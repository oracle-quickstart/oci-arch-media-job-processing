## Copyright © 2021, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_identity_dynamic_group" "instances" {
  provider       = oci.homeregion
  name           = "WorkerInstancesDynamicGroup"
  description    = "All instances in the ${data.oci_identity_compartment.compartment.name} compartment."
  compartment_id = var.tenancy_ocid
  matching_rule  = "ALL {instance.compartment.id = '${var.compartment_ocid}'}"
  defined_tags   = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}

resource "oci_identity_dynamic_group" "api_gateways" {
  provider       = oci.homeregion
  name           = "QueueApiGatewayDynamicGroup"
  description    = "All API Gateways in the ${data.oci_identity_compartment.compartment.name} compartment."
  compartment_id = var.tenancy_ocid
  matching_rule  = "ALL {resource.type = 'ApiGateway', resource.compartment.id = '${var.compartment_ocid}'}"
  defined_tags   = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}

resource "oci_identity_dynamic_group" "functions" {
  provider       = oci.homeregion
  name           = "JobFunctionsServiceDynamicGroup"
  description    = "All functions in the ${data.oci_identity_compartment.compartment.name} compartment."
  compartment_id = var.tenancy_ocid
  matching_rule  = "ALL {resource.type = 'fnfunc', resource.compartment.id = '${var.compartment_ocid}'}"
  defined_tags   = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}


resource "oci_identity_policy" "job_managmement_policy" {
  provider       = oci.homeregion
  name           = "job_managmement_policy"
  description    = "job_managmement_policy"
  compartment_id = var.tenancy_ocid
  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.functions.name} to manage all-resources in compartment ${data.oci_identity_compartment.compartment.name}",
    "Allow dynamic-group ${oci_identity_dynamic_group.instances.name} to manage all-resources in compartment ${data.oci_identity_compartment.compartment.name}",
    "Allow dynamic-group ${oci_identity_dynamic_group.api_gateways.name} to use functions-family in compartment ${data.oci_identity_compartment.compartment.name}"
  ]
  defined_tags = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}
