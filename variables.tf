## Copyright © 2021, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

variable "release" {
  description = "Reference Architecture Release (OCI Architecture Center)"
  default     = "1.0"
}

variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "region" {}

variable "compartment_ocid" {
  type        = string
  description = "The compartment that resources will be deployed in."
}

variable "email_address" {
  type        = string
  default     = "nobody@oracle.com"
  description = "Job status emails will be sent to this address."
  validation {
    condition     = length(var.email_address) > 0
    error_message = "Required."
  }
}

variable "source_bucket_name" {
  type    = string
  default = "transcode_source"
}

variable "destination_bucket_name" {
  type    = string
  default = "transcode_destination"
}

variable "vcn_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  type    = string
  default = "10.0.0.0/24"
}
variable "ocir_repo_name" {
  type    = string
  default = "job_management"
}

variable "ocir_user_name" {
  type        = string
  description = "User name that will push docker images to the container registry."
  validation {
    condition     = length(var.ocir_user_name) > 0
    error_message = "Required."
  }
}

variable "ocir_password" {
  type        = string
  description = "Auth Token for the user that will push docker images to the container registry."
  sensitive   = true
  validation {
    condition     = length(var.ocir_password) > 0
    error_message = "Required."
  }
}

variable "create_job_function_version" {
  type    = string
  default = "1.0.0"

}
variable "launch_worker_function_version" {
  type    = string
  default = "1.0.0"

}

variable "check_preempted_worker_function_version" {
  type    = string
  default = "1.0.0"

}
variable "retry_queued_function_version" {
  type    = string
  default = "1.0.0"

}

