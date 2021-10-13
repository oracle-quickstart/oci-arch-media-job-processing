## Copyright © 2021, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_logging_log_group" "job_management" {
  compartment_id = var.compartment_ocid
  description    = "job_management"
  display_name   = "job_management"
  defined_tags   = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}

resource "oci_logging_log" "job_management_invoke" {
  configuration {
    compartment_id = var.compartment_ocid
    source {
      category    = "invoke"
      resource    = oci_functions_application.job_management.id
      service     = "functions"
      source_type = "OCISERVICE"
    }
  }
  display_name       = "job_management_invoke"
  is_enabled         = "true"
  log_group_id       = oci_logging_log_group.job_management.id
  log_type           = "SERVICE"
  retention_duration = "30"
  defined_tags       = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}

resource "oci_logging_log" "api_gateway_execution" {
  configuration {
    compartment_id = var.compartment_ocid
    source {
      category    = "execution"
      resource    = oci_apigateway_deployment.job_management.id
      service     = "apigateway"
      source_type = "OCISERVICE"
    }
  }
  display_name       = "api_gateway_execution"
  is_enabled         = "true"
  log_group_id       = oci_logging_log_group.job_management.id
  log_type           = "SERVICE"
  retention_duration = "30"
  defined_tags       = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}

resource "oci_logging_log" "create_job_event" {
  configuration {
    compartment_id = var.compartment_ocid
    source {
      category    = "ruleexecutionlog"
      resource    = oci_events_rule.create_job.id
      service     = "cloudevents"
      source_type = "OCISERVICE"
    }
  }
  display_name       = "create_job_event"
  is_enabled         = "true"
  log_group_id       = oci_logging_log_group.job_management.id
  log_type           = "SERVICE"
  retention_duration = "30"
  defined_tags       = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}

resource "oci_logging_log" "check_preempted_worker_event" {
  configuration {
    compartment_id = var.compartment_ocid
    source {
      category    = "ruleexecutionlog"
      resource    = oci_events_rule.preemptible_event.id
      service     = "cloudevents"
      source_type = "OCISERVICE"
    }
  }
  display_name       = "check_preempted_worker_event"
  is_enabled         = "true"
  log_group_id       = oci_logging_log_group.job_management.id
  log_type           = "SERVICE"
  retention_duration = "30"
  defined_tags       = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}
