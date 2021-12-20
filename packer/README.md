# Build Custom Worker Image with Packer

[HashiCorp Packer](https://www.packer.io/) uses similar configuration values as the OCI CLI and Terraform. 
## Packer Setup

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
      - *ol_base_image_ocid* - Find the Image OCID for the most recent [Oracle Linux 8](https://docs.oracle.com/en-us/iaas/images/oracle-linux-8x/) version for the OCI Region that Packer will use.

## Packer Build

1.  Open a terminal session and navigate to the `Packer` directory.
2.  Run `sh build` or `packer build -var-file=worker.pkrvars.hcl worker.pkr.hcl`. **Note:** This build takes about 24 minutes to complete.
3. An image OCID is shown after a successful build. You do not need to save this OCID, Terraform will discover it automatically.
4. Terminate the temporary Packer VCN.