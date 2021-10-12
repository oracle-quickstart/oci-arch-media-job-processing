## Copyright © 2021, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_ons_notification_topic" "job_status" {
  compartment_id = var.compartment_ocid
  description    = "job_status"
  name           = "job_status"
  defined_tags   = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}

resource "oci_ons_subscription" "email_subscription" {
  compartment_id  = var.compartment_ocid
  delivery_policy = "{\"backoffRetryPolicy\":{\"maxRetryDuration\":7200000,\"policyType\":\"EXPONENTIAL\"}}"
  endpoint        = var.email_address
  protocol        = "EMAIL"
  topic_id        = oci_ons_notification_topic.job_status.id
  defined_tags    = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}
