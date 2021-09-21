resource "oci_events_rule" "create_job" {
  actions {
    actions {
      action_type = "FAAS"
      function_id = oci_functions_function.create_job.id
      is_enabled  = "true"
    }
  }
  compartment_id = var.compartment_ocid
  condition      = "{\"eventType\":[\"com.oraclecloud.objectstorage.createobject\"],\"data\":{\"compartmentName\":[\"${data.oci_identity_compartment.compartment.name}\"],\"additionalDetails\":{\"bucketName\":[\"${oci_objectstorage_bucket.source_bucket.name}\"]}}}"
  display_name   = "create_job"
  is_enabled     = "true"
}

resource "oci_events_rule" "preemptible_event" {
  actions {
    actions {
      action_type = "FAAS"
      function_id = oci_functions_function.check_preempted_worker.id
      is_enabled  = "true"
    }
  }
  compartment_id = var.compartment_ocid
  condition      = "{\"eventType\":[\"com.oraclecloud.computeapi.instancepreemptionaction\"],\"data\":{\"compartmentName\":[\"${data.oci_identity_compartment.compartment.name}\"],\"additionalDetails\":{\"preemptionAction\":[\"TERMINATE\"]}}}"
  display_name   = "preemptible_event"
  is_enabled     = "true"
}



