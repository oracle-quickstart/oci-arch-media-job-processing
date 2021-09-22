#!/bin/bash

exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>/home/opc/logs/run.log 2>&1

export OCI_CLI_AUTH=instance_principal

instance_metadata=$(curl -s -H "Authorization: Bearer Oracle" -L http://169.254.169.254/opc/v2/instance/)

compartment_id=$(jq -r '.compartmentId'<<< ${instance_metadata})
instance_id=$(jq -r '.id'<<< ${instance_metadata})
file_name=$(jq -r '.metadata .file_name'<<< ${instance_metadata})
event_id=$(jq -r '.metadata .event_id'<<< ${instance_metadata})
topic_id=$(jq -r '.metadata .topic_id'<<< ${instance_metadata})
source_bucket_name=$(jq -r '.metadata .source_bucket_name'<<< ${instance_metadata})
destination_bucket_name=$(jq -r '.metadata .destination_bucket_name'<<< ${instance_metadata})
nosql_table_name=$(jq -r '.metadata .nosql_table_name'<<< ${instance_metadata})

# Instance launched without a file to process.
if [ ${file_name} == "null" ] ; then
     exit 1
fi

output_file=`echo ${file_name} | awk -F. '{print$1}'`.mp4

oci nosql query execute --compartment-id $compartment_id --statement="UPDATE ${nosql_table_name} d set d.status = \"Validating Input\" where d.event_id=\"${event_id}\""
oci os object get --bucket-name ${source_bucket_name} --name "${file_name}"  --file -  | /home/opc/bin/ffmpeg -v error -i -  -f null - 2>/tmp/error_before_encoding.log
if [ -s /tmp/error_before_encoding.log ]
 then
     echo "Transcode: File validation error."
     oci nosql query execute --compartment-id $compartment_id --statement="UPDATE ${nosql_table_name} d set d.status = \"Input Validation Error\" where d.event_id=\"${event_id}\""
     body="Error in source file. Please delete, review, and re-upload the correct file for encoding ${file_name}"
     oci ons message publish --topic-id $topic_id --title 'Transcode Status' --body "$body"
else
     echo "Transcode: File validated."
     oci nosql query execute --compartment-id $compartment_id --statement="UPDATE ${nosql_table_name} d set d.status = \"Processing\" where d.event_id=\"${event_id}\""
     oci os object get --bucket-name ${source_bucket_name} --name "${file_name}" --file -  | /home/opc/bin/ffmpeg -i - -vcodec h264 -acodec aac -strict -2 -movflags frag_keyframe+empty_moov -f mp4 - | oci os object put --bucket-name ${destination_bucket_name} --name "${output_file}" --force --file -
     oci nosql query execute --compartment-id $compartment_id --statement="UPDATE ${nosql_table_name} d set d.status = \"Validating Output\" where d.event_id=\"${event_id}\""
     oci os object get --bucket-name ${destination_bucket_name} --name "${output_file}"  --file -  | /home/opc/bin/ffmpeg -v error -i -  -f null - 2>/tmp/error_post_encoding.log
     if [ -s /tmp/error_post_encoding.log ]
       then
          echo "Transcode: Encoding error."
          oci nosql query execute --compartment-id $compartment_id --statement="UPDATE ${nosql_table_name} d set d.status = \"Output Validation Error\" where d.event_id=\"${event_id}\""
          body="Error when encoding ${file_name}."
          oci ons message publish --topic-id $topic_id --title 'Transcode Status' --body "$body"
     else
         echo "Transcode: Encoding complete."
         oci nosql query execute --compartment-id $compartment_id --statement="UPDATE ${nosql_table_name} d set d.status = \"Done\" where d.event_id=\"${event_id}\""
         body="Encoding complete for file ${file_name}."
         oci ons message publish --topic-id $topic_id --title 'Transcode Status' --body "$body"
     fi
fi

echo "Transcode: Terminating worker."
oci compute instance terminate --instance-id $instance_id --force