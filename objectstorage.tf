resource "oci_objectstorage_bucket" "source_bucket" {
  compartment_id        = var.compartment_ocid
  name                  = var.source_bucket_name
  namespace             = data.oci_objectstorage_namespace.tenancy_namespace.namespace
  access_type           = "NoPublicAccess"
  object_events_enabled = "true"
  storage_tier          = "Standard"
  versioning            = "Disabled"
}

resource "oci_objectstorage_bucket" "destination_bucket" {
  compartment_id        = var.compartment_ocid
  name                  = var.destination_bucket_name
  namespace             = data.oci_objectstorage_namespace.tenancy_namespace.namespace
  access_type           = "NoPublicAccess"
  object_events_enabled = "true"
  storage_tier          = "Standard"
  versioning            = "Disabled"
}
