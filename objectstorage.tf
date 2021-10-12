## Copyright © 2021, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_objectstorage_bucket" "source_bucket" {
  compartment_id        = var.compartment_ocid
  name                  = var.source_bucket_name
  namespace             = data.oci_objectstorage_namespace.tenancy_namespace.namespace
  access_type           = "NoPublicAccess"
  object_events_enabled = "true"
  storage_tier          = "Standard"
  versioning            = "Disabled"
  defined_tags          = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}

resource "oci_objectstorage_bucket" "destination_bucket" {
  compartment_id        = var.compartment_ocid
  name                  = var.destination_bucket_name
  namespace             = data.oci_objectstorage_namespace.tenancy_namespace.namespace
  access_type           = "NoPublicAccess"
  object_events_enabled = "true"
  storage_tier          = "Standard"
  versioning            = "Disabled"
  defined_tags          = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}
