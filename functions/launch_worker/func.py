import oci
import oci.object_storage
from borneo import (
   PutRequest, QueryRequest, NoSQLHandle, NoSQLHandleConfig, PrepareRequest)
from borneo.iam import SignatureProvider
from fdk import response

import io
import json
import logging
import logging.handlers
import logging.config

def handler(ctx, data: io.BytesIO = None):
    func_name = ctx.FnName()
    global logger
    logger = logging.getLogger(func_name)
    logger.setLevel(logging.INFO)
    logger.info("Function started.")
    
    try:
        cfg = ctx.Config()
        global endpoint, compartment,table_name,image_id,subnet_id,topic_id,source_bucket_name,destination_bucket_name,availability_domain,shape_name,preempt_shape_name
        endpoint = cfg["ENDPOINT"]
        compartment = cfg["COMPARTMENT"]     
        table_name = cfg["NOSQL_TABLE_NAME"]
        image_id = cfg["WORKER_IMAGE_ID"]  
        subnet_id = cfg["SUBNET"]  
        topic_id = cfg["TOPIC_ID"] 
        source_bucket_name = cfg["SOURCE_BUCKET_NAME"]  
        destination_bucket_name = cfg["DESTINATION_BUCKET_NAME"] 
        availability_domain = cfg["AVAILABILITY_DOMAIN"]   
        shape_name = cfg["SHAPE"]
        preempt_shape_name = cfg["PREEMPT_SHAPE"]
    except Exception:
        logger.error("Missing function parameters.")
        raise
    
    try:
        body = json.loads(data.getvalue())
        event_id = body.get("event_id")
        nosql_get_object_name (event_id)
    except (Exception) as ex:
        logger.error("Function error: " + ex)
        raise

    logger.info("Function complete.")
    return response.Response(
        ctx,
        response_data=json.dumps(body),
        headers={"Content-Type": "application/json"}
    )

def nosql_get_object_name (event_id):
   handle = None
   try:
       # Silence NoSQL client debug logs
       urllib3_logger = logging.getLogger('urllib3')
       urllib3_logger.setLevel(logging.WARN)
       oci_logger = logging.getLogger('oci')
       oci_logger.setLevel(logging.WARN)

       signer = oci.auth.signers.get_resource_principals_signer()
       NoSQLprovider = SignatureProvider(provider=signer)
       NoSQLconfig = NoSQLHandleConfig(endpoint,NoSQLprovider).set_default_compartment(compartment).set_logger(logger)
       handle = NoSQLHandle(NoSQLconfig)
       statement = 'select object_name from ' + table_name + ' where event_id = "'+ event_id +'"'
       request = PrepareRequest().set_statement(statement)
       prepared_result = handle.prepare(request)
       request = QueryRequest().set_prepared_statement(prepared_result)
       while True:
            result = handle.query(request)
            for r in result.get_results():
                s = json.dumps(r)
                data = json.loads(s)
                object_name = data['object_name']
                launch_instance_every_object (event_id,object_name)
            if request.is_done():
                break
   finally:
        if handle is not None:
            handle.close()

def launch_instance_every_object (event_id,object_name):
    
    if image_id == "no_worker":
        failed_setup_message = "No worker image found. Please see README for worker image creation."
        status = "Done"
        instance_id = failed_setup_message
        capacity = image_id
        nosql_update_instance_id (event_id,object_name,status,instance_id,capacity)
        logger.error(failed_setup_message)
        return

    signer = oci.auth.signers.get_resource_principals_signer()
    compute_client = oci.core.ComputeClient(config={}, signer=signer)
    compute_client_composite_operations = oci.core.ComputeClientCompositeOperations(compute_client)

    instance_name_prefix = 'ffmpeg_worker'

    instance_source_via_image_details = oci.core.models.InstanceSourceViaImageDetails(
        image_id=image_id
    )

    preemptible_instance_config = oci.core.models.PreemptibleInstanceConfigDetails ( 
        preemption_action = oci.core.models.PreemptionAction(type = 'TERMINATE')
    )
    shape_config = oci.core.models.LaunchInstanceShapeConfigDetails (ocpus=1.0, memory_in_gbs=16.0, baseline_ocpu_utilization='BASELINE_1_1')
    


    create_vnic_details = oci.core.models.CreateVnicDetails(
        subnet_id=subnet_id
    )

    instance_metadata = {
        'file_name': object_name,
        'event_id': event_id,
        'topic_id': topic_id,
        'nosql_table_name': table_name,
        'source_bucket_name': source_bucket_name,
        'destination_bucket_name': destination_bucket_name
    }

    try:
        logger.info("Launching preemptible worker for " + object_name + ".")
        launch_instance_details = oci.core.models.LaunchInstanceDetails(
            display_name=(instance_name_prefix+'-'+event_id),
            compartment_id=compartment,
            availability_domain=availability_domain,
            shape_config=shape_config,
            shape=preempt_shape_name,
            metadata=instance_metadata,
            source_details=instance_source_via_image_details,
            create_vnic_details=create_vnic_details,
            preemptible_instance_config = preemptible_instance_config
        )
        launch_instance_response = compute_client_composite_operations.launch_instance_and_wait_for_state(
            launch_instance_details,
            wait_for_states=[oci.core.models.Instance.LIFECYCLE_STATE_PROVISIONING]
        )
        instance = launch_instance_response.data
        instance_id=instance.id
        status = 'VM Worker Launched'
        capacity = 'Preemptible'
        logger.info("Preemptible worker launched.")
        nosql_update_instance_id (event_id,object_name,status,instance_id,capacity)
    
    except:
           logger.warn("No preemptible capacity available.")
           try: 
               logger.info("Launching on-demand worker for " + object_name + ".")
               launch_instance_details = oci.core.models.LaunchInstanceDetails(
                   display_name=(instance_name_prefix+'-'+event_id),
                   compartment_id=compartment,
                   availability_domain=availability_domain,
                   shape=shape_name,
                   metadata=instance_metadata,
                   source_details=instance_source_via_image_details,
                   create_vnic_details=create_vnic_details
               )
                
               launch_instance_response = compute_client_composite_operations.launch_instance_and_wait_for_state(
               launch_instance_details,
                   wait_for_states=[oci.core.models.Instance.LIFECYCLE_STATE_PROVISIONING]
               )

               instance = launch_instance_response.data
               instance_id=instance.id
               status = 'VM Worker Launched'
               capacity = 'On-Demand'
               logger.info("On-demand worker launched.")
               nosql_update_instance_id (event_id,object_name,status,instance_id,capacity)
           except:
                  logger.error("No on-demand capacity available.")
    
def nosql_update_instance_id (event_id,object_name,status,instance_id,capacity):
   handle = None
   try:
       logger.info("Updating job with instance ID.")

       # Silence NoSQL client debug logs
       urllib3_logger = logging.getLogger('urllib3')
       urllib3_logger.setLevel(logging.WARN)
       oci_logger = logging.getLogger('oci')
       oci_logger.setLevel(logging.WARN)

       signer = oci.auth.signers.get_resource_principals_signer()
       NoSQLprovider = SignatureProvider(provider=signer)
       NoSQLconfig = NoSQLHandleConfig(endpoint,NoSQLprovider).set_default_compartment(compartment).set_logger(logger)
       handle = NoSQLHandle(NoSQLconfig)
       request = PutRequest().set_table_name(table_name)
       value = {'event_id': str(event_id), 'object_name': str(object_name), 'status': str(status), 'instance_id': str(instance_id),'Capacity': str(capacity)}
       request.set_value(value)
       handle.put(request)

   finally:
        if handle is not None:
            handle.close()