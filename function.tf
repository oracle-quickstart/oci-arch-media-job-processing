## Copyright © 2021, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_functions_application" "job_management" {
  compartment_id = var.compartment_ocid
  display_name   = "job_management"
  subnet_ids     = [oci_core_subnet.private_subnet.id]
  syslog_url     = ""
  defined_tags   = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }

}

resource "oci_functions_function" "create_job" {
  depends_on     = [null_resource.create_job_fn_setup]
  application_id = oci_functions_application.job_management.id
  display_name   = "create_job"
  image          = "${local.ocir_docker_repository}/${data.oci_objectstorage_namespace.tenancy_namespace.namespace}/create_job:${var.create_job_function_version}"
  memory_in_mbs  = "256"
  config = {
    "ENDPOINT" : var.region
    "COMPARTMENT" : var.compartment_ocid
    "NOSQL_TABLE_NAME" : oci_nosql_table.job_tracking.name
    "FUNCTION_ENDPOINT" : oci_functions_function.launch_worker.invoke_endpoint
    "FUNCTION_OCID" : oci_functions_function.launch_worker.id
  }
  defined_tags = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
}

resource "oci_functions_function" "launch_worker" {
  depends_on     = [null_resource.launch_worker_fn_setup]
  application_id = oci_functions_application.job_management.id
  display_name   = "launch_worker"
  image          = "${local.ocir_docker_repository}/${data.oci_objectstorage_namespace.tenancy_namespace.namespace}/launch_worker:${var.launch_worker_function_version}"
  memory_in_mbs  = "256"
  config = {
    "ENDPOINT" : var.region
    "COMPARTMENT" : var.compartment_ocid
    "NOSQL_TABLE_NAME" : oci_nosql_table.job_tracking.name
    "WORKER_IMAGE_ID" : data.oci_core_images.worker.images[0].id
    "SUBNET" : oci_core_subnet.private_subnet.id
    "TOPIC_ID" : oci_ons_notification_topic.job_status.id
    "SOURCE_BUCKET_NAME" : oci_objectstorage_bucket.source_bucket.name
    "DESTINATION_BUCKET_NAME" : oci_objectstorage_bucket.destination_bucket.name
    "AVAILABILITY_DOMAIN" : data.oci_identity_availability_domains.availability_domains.availability_domains[0].name
    "SHAPE" : "VM.Standard2.1"
    "PREEMPT_SHAPE" : "VM.Standard.E3.Flex"
  }
  defined_tags = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
}

resource "oci_functions_function" "check_preempted_worker" {
  depends_on     = [null_resource.check_preempted_worker_fn_setup]
  application_id = oci_functions_application.job_management.id
  display_name   = "check_preempted_worker"
  image          = "${local.ocir_docker_repository}/${data.oci_objectstorage_namespace.tenancy_namespace.namespace}/check_preempted_worker:${var.check_preempted_worker_function_version}"
  memory_in_mbs  = "256"
  config = {
    "ENDPOINT" : var.region
    "COMPARTMENT" : var.compartment_ocid
    "NOSQL_TABLE_NAME" : oci_nosql_table.job_tracking.name
    "FUNCTION_ENDPOINT" : oci_functions_function.launch_worker.invoke_endpoint
    "FUNCTION_OCID" : oci_functions_function.launch_worker.id
  }
  defined_tags = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
}

resource "oci_functions_function" "retry_queued" {
  depends_on     = [null_resource.retry_queued_fn_setup]
  application_id = oci_functions_application.job_management.id
  display_name   = "retry_queued"
  image          = "${local.ocir_docker_repository}/${data.oci_objectstorage_namespace.tenancy_namespace.namespace}/retry_queued:${var.retry_queued_function_version}"
  memory_in_mbs  = "256"
  config = {
    "ENDPOINT" : var.region
    "COMPARTMENT" : var.compartment_ocid
    "NOSQL_TABLE_NAME" : oci_nosql_table.job_tracking.name
    "FUNCTION_ENDPOINT" : oci_functions_function.launch_worker.invoke_endpoint
    "FUNCTION_OCID" : oci_functions_function.launch_worker.id
  }
  defined_tags = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
}

