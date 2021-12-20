# oci-arch-media-job-processing

Processing large media files can be a resource intensive operation requiring large compute shapes for timely and efficient processing. In scenarios where media processing requests might be ad-hoc and on-demand, leaving instances idle while waiting for new work is not cost effective.

By utilizing Oracle Cloud Infrastructure's (OCI) server-less capabilities, including OCI Functions and OCI NoSQL, we can quickly create a management system for processing media content using ephemeral OCI Compute workers.


For details of the architecture, see [Process media by using serverless job management and ephemeral compute workers](https://docs.oracle.com/en/solutions/process-media-using-oci-services/index.html)

## Prerequisites

- [Packer](https://www.packer.io/) - Installed locally.
- [OCI API Key](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm) - Used for executing Packer and Terraform.
- [OCI Auth Token](https://docs.oracle.com/en-us/iaas/Content/Registry/Tasks/registrygettingauthtoken.htm) - Used for pushing images to an OCI container registry using Terraform.

Additionally required when ***not*** deploying with OCI Resource Manager.

- [Docker CLI](https://www.docker.com/) - Installed locally.
- [Terraform](https://www.terraform.io/) - Installed locally.

## Deploy Using Oracle Resource Manager

1. Click [![Deploy to Oracle Cloud](https://oci-resourcemanager-plugin.plugins.oci.oraclecloud.com/latest/deploy-to-oracle-cloud.svg)](https://console.us-ashburn-1.oraclecloud.com/resourcemanager/stacks/create?region=home&zipUrl=https://github.com/oracle-quickstart/oci-arch-media-job-processing/releases/latest/download/oci-arch-media-job-processing-stack-latest.zip)

    If you aren't already signed in, when prompted, enter the tenancy and user credentials.

2. Review and accept the terms and conditions.

3. Select the region where you want to deploy the stack.

4. Follow the on-screen prompts and instructions to create the stack.

5. After creating the stack, click **Terraform Actions**, and select **Plan**.

6. Wait for the job to be completed, and review the plan.

    To make any changes, return to the Stack Details page, click **Edit Stack**, and make the required changes. Then, run the **Plan** action again.

7. If no further changes are necessary, return to the Stack Details page, click **Terraform Actions**, and select **Apply**. 

## Deploy Using the Terraform CLI

### Clone the Repository
Now, you'll want a local copy of this repo. You can make that with the commands:

    git clone https://github.com/oracle-quickstart/oci-arch-media-job-processing.git
    cd oci-arch-media-job-processing
    ls

2. Create a `terraform.tfvars` file, and specify the following variables:

```
# Authentication
tenancy_ocid         = "<tenancy_ocid>"
user_ocid            = "<user_ocid>"
fingerprint          = "<finger_print>"
private_key_path     = "<pem_private_key_path>"

# Region
region = "<oci_region>"

# Compartment
compartment_ocid = "<compartment_ocid>"

# OCI Image Repository Credentials
ocir_user_name   = "User name that will push docker images to the container registry."
ocir_password    = "Auth Token for the user that will push docker images to the container registry."

# Job Notifications
email_address    = "Job status emails will be sent to this address."
```

### Create the Resources
Run the following commands:

    terraform init
    terraform plan
    terraform apply

### Destroy the Deployment
When you no longer need the deployment, you can run this command to destroy the resources:

    terraform destroy

**Note:** Any media objects created as part of operating this demo will prevent Terraform from fully cleaning up resources.

1. Delete any objects and uncommitted multipart uploads in the `source_bucket_name` bucket.
2. Delete any objects and uncommitted multipart uploads in the `destination_bucket_name` bucket.

The `oci_functions_application` and `oci_ons_notification_topic` resources take some time to be terminated. The `terraform destroy` process for this configuration normally take more than 15 minutes to run.

After the Terraform configuration has been destroyed, delete the custom woker image and delete the compartment that was created for the deployment.

## Create Worker Image

Prior to the deployment being functional, an OCI Compute Custom Image needs to be created for the worker instances using Packer. For Packer usage and custom image creation, see [packer/README.md](packer/README.md).

After the custom image is created, the `WORKER_IMAGE_ID` configuration variable value of the `launch_worker` function need to be updated with the image OCID. The value can set mauanlly or by re-running the Oracle Resounce Manager or Terraform CLI apply commands.
## Usage

To use this demo, upload a video file to the `source_bucket_name` bucket. A successful upload will trigger the media processing workflow below.
### Media Processing Workflow

1. A video is uploaded to the source object storage bucket.
2. An `objectstorage.createobject` event is sent to the `create_job` function.
3. The `create_job` function adds a record to the `job_tracking` NoSQL table and calls the `launch_worker` function for the job.
4. When launched, the worker instance reads the source video and outptuts a new MP4 file with H.264 and AAC encoding to the destination object storage bucket.
5. During processing, the worker updates the `job_tracking` NoSQL table and sends job status notifications.
6. When processing is complete, the worker terminates itself.

### Job Management
Media processing jobs are managed using a Python functions and job state is stored in an OCI NoSQL table. If a worker cannot be launched to process a job due to reaching a limit or quota, a regular health check will attempt the launch later. All job management functions send logs to OCI Logging.
### Worker Deployment

One compute worker instance is launched per job. By default, [preemptible](https://docs.oracle.com/en-us/iaas/Content/Compute/Concepts/preemptible.htm) capacity is used when launching workers. If preemptible capacity is not available, a worker is lanched using [on-demand](https://docs.oracle.com/en-us/iaas/Content/Compute/Concepts/capacity-types.htm) capacity. 