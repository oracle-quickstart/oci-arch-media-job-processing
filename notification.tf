resource "oci_ons_notification_topic" "job_status" {
  compartment_id = var.compartment_ocid
  description    = "job_status"
  name           = "job_status"
}

resource "oci_ons_subscription" "email_subscription" {
  compartment_id  = var.compartment_ocid
  delivery_policy = "{\"backoffRetryPolicy\":{\"maxRetryDuration\":7200000,\"policyType\":\"EXPONENTIAL\"}}"
  endpoint        = var.email_address
  protocol        = "EMAIL"
  topic_id        = oci_ons_notification_topic.job_status.id
}