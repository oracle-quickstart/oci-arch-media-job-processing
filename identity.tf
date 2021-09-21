resource "oci_identity_dynamic_group" "instances" {
  provider       = oci.home
  name           = "WorkerInstancesDynamicGroup"
  description    = "All instances in the ${data.oci_identity_compartment.compartment.name} compartment."
  compartment_id = var.tenancy_ocid
  matching_rule  = "ALL {instance.compartment.id = '${var.compartment_ocid}'}"
}

resource "oci_identity_dynamic_group" "api_gateways" {
  provider       = oci.home
  name           = "QueueApiGatewayDynamicGroup"
  description    = "All API Gateways in the ${data.oci_identity_compartment.compartment.name} compartment."
  compartment_id = var.tenancy_ocid
  matching_rule  = "ALL {resource.type = 'ApiGateway', resource.compartment.id = '${var.compartment_ocid}'}"
}

resource "oci_identity_dynamic_group" "functions" {
  provider       = oci.home
  name           = "JobFunctionsServiceDynamicGroup"
  description    = "All functions in the ${data.oci_identity_compartment.compartment.name} compartment."
  compartment_id = var.tenancy_ocid
  matching_rule  = "ALL {resource.type = 'fnfunc', resource.compartment.id = '${var.compartment_ocid}'}"
}


resource "oci_identity_policy" "job_managmement_policy" {
  provider       = oci.home
  name           = "job_managmement_policy"
  description    = "job_managmement_policy"
  compartment_id = var.tenancy_ocid
  statements = [
    #"Allow service FaaS to read repos in tenancy",
    #"Allow service FaaS to use virtual-network-family in compartment ${data.oci_identity_compartment.compartment.name}",
    "Allow dynamic-group ${oci_identity_dynamic_group.functions.name} to manage all-resources in compartment ${data.oci_identity_compartment.compartment.name}",
    "Allow dynamic-group ${oci_identity_dynamic_group.instances.name} to manage all-resources in compartment ${data.oci_identity_compartment.compartment.name}",
    "Allow dynamic-group ${oci_identity_dynamic_group.api_gateways.name} to use functions-family in compartment ${data.oci_identity_compartment.compartment.name}"
  ]
}