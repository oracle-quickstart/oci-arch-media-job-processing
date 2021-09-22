# Overview

This Terraform deploys Oracle Cloud Infrastructure resources to implement the [Media processing using serverless job management and ephemeral compute workers](https://docs.oracle.com/en/solutions/media-processing-using-serverless-job-management-and-ephemeral-compute-workers) Reference Architecture.

# Prerequisites

- [Packer](https://www.packer.io/) - Installed locally.
- [OCI API Key](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm) - Used for executing Packer and Terraform.
- [OCI Auth Token](https://docs.oracle.com/en-us/iaas/Content/Registry/Tasks/registrygettingauthtoken.htm) - Used for pushing images to an OCI containter registry using Terraform.

Additionally required when ***not*** deploying with OCI Resource Manager.

- [Docker](https://www.docker.com/) - Installed locally.
- [Terraform](https://www.terraform.io/) - Installed locally.

# Demo Deployment

The compute workers in this demo utilize a custom compute image that must be available prior to using OCI Resource Manager or Terraform. The deployment process is done in two steps:

1. [Build Custom Worker Image](#build-custom-worker-image-with-packer)
2. [Deploy Resources](#deploy-resources)

## Build Custom Worker Image with Packer

[HashiCorp Packer](https://www.packer.io/) uses similar configuration values as the OCI CLI and Terraform. 
### Packer Setup

1. Create a deployment compartment in the target OCI tenancy. This compartment is used for both Packer and Terraform resources.
2. Create a temporary Packer VCN for the build process. The [Create a VCN with Internet Connectivity](https://console.us-sanjose-1.oraclecloud.com/networking/solutions/vcn) wizard from the Networking landing page in the OCI console can be used. 
3. Use `Packer/worker.pkrvars.hcl.example` as a template to create `Packer/worker.pkrvars.hcl`.
4. Configure the OCI Tenancy variables in `Packer/worker.pkrvars.hcl`. **Note:** *private_key_path* in Terraform is *key_file* in Packer.
      - *tenancy_ocid*
      - *user_ocid*
      - *fingerprint*
      - *key_file*
      - *region*
      - *compartment_ocid* - The OCID of the Compartment created in step #1.
5. Configure Network variables in `Packer/worker.pkrvars.hcl`.
      - *availability_domain*
      - *subnet_ocid* - The OCID of the Public Subnet created in step #2.
6. Configure the Oracle Linux 8 variable in `Packer/worker.pkrvars.hcl`. 
      - *ol_base_image_ocid* - Find the Image OCID for the most recent [Oracle Linux 8](https://docs.oracle.com/en-us/iaas/images/oraclelinux-8x/) version for the OCI Region that Packer will use.

### Packer Build

1.  Open a terminal session and navigate to the `Packer` directory.
2.  Run `sh build` or `packer build -var-file=worker.pkrvars.hcl worker.pkr.hcl`. **Note:** This build takes about 24 minutes to complete.
3. An image OCID is shown after a sucessful build. You do not need to save this OCID, Terraform will discover it automatically.
4. Terminate the temporary Packer VCN.

## Deploy Resources

OCI Resources can be deployed using OCI Resource Manager or by running Terraform locally.

### Resource Manager Deplyment

1. Download [Stack.zip](Stack.zip).
2. Create an OCI Resource Manager Stack using Stack.zip in the compartment previously created in the [Build Custom Worker Image with Packer](#build-custom-worker-image-with-packer) section.
3. Configure variables for the Stack.
      - *email_address* - worker status emails will be sent to this address.
      - *ocir_user_name* - User name that will push docker images to the container registry. Be sure to use the full username, including `oracleidentitycloudservice/` if using an IDCS user.
      - *ocir_password* - Auth Token for the user that will push docker images to the container registry.
4. Deploy the Stack.

### Terraform Deployment

1. Start Docker.
2. Use `terraform.tfvars.example` as a template to create `terraform.tfvars`. Some of the variable from `Packer/worker.pkrvars.hcl` can be reused.
      - *tenancy_ocid* 
      - *user_ocid*
      - *fingerprint*
      - *private_key_path* - key_file from `Packer/worker.pkrvars.hcl`.
      - *region*
      - *compartment_ocid* - The compartment previously created in the [Build Custom Worker Image with Packer](#build-custom-worker-image-with-packer) section.
      - *ocir_user_name* - User name that will push docker images to the container registry. Be sure to use the full username, including `oracleidentitycloudservice/` if using an IDCS user.
      - *ocir_password* - Auth Token for the user that will push docker images to the container registry.
      - *email_address* - worker status emails will be sent to this address.
3. Run `terraform apply`.

# Demo Usage

To use this demo, upload a video file to the `source_bucket_name` bucket. A sucessful upload will trigger the media processing workflow below.
## Media Processing Workflow

1. A video is uploaded to the source object storage bucket.
2. An `objectstorage.createobject` event is sent to the `create_job` function.
3. The `create_job` function adds a record to the `job_tracking` NoSQL table and calls the `launch_worker` funciton for the job.
4. When launched, the worker instance reads the source video and outptuts a new MP4 file with H.264 and AAC encoding to the destination object storage bucket.
5. During the processing, the worker updates the `job_tracking` NoSQL table and triggers job status notification emails.
6. When processing is compelete, the worker terminates itself.

## Job Management
Media processing jobs are managed using a Python functions and job state is stored in an OCI NoSQL table. If a worker cannot be launched to process a job due to reaching a limit or quota, an hourly health check will attempt the launch later. All job management functions send logs to OCI Logging.
## Worker Deployment

One compute worker instance is launched per job. By default, [preemptible](https://docs.oracle.com/en-us/iaas/Content/Compute/Concepts/preemptible.htm) capacity is used when launching wokers. If preemptible capacity is not available, a worker is lanched using [on-demand](https://docs.oracle.com/en-us/iaas/Content/Compute/Concepts/capacity-types.htm) capacity. 

# Demo Cleanup

Any media objects created as part of operating this demo will prevent Terraform from fully cleaning up resources.

1. Delete any objects and uncommitted multipart uploads in the `source_bucket_name` bucket.
2. Delete any objects and uncommitted multipart uploads in the `destination_bucket_name` bucket.

The `oci_functions_application` and `oci_ons_notification_topic` resources take some time to be terminated. The `terraform destroy` process for this configuration normally take more than 15 minutes to run.

After the Terraform configuration has been destroyed, delete the custom woker image and delete the compartment that was created for the deployment.