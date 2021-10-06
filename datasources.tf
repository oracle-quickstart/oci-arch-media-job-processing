## Copyright © 2021, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

data "oci_identity_tenancy" "tenancy" {
  tenancy_id = var.tenancy_ocid
}

data "oci_identity_compartment" "compartment" {
  id = var.compartment_ocid
}

data "oci_identity_regions" "regions" {
}

data "oci_objectstorage_namespace" "tenancy_namespace" {
  compartment_id = var.tenancy_ocid
}

data "oci_identity_availability_domains" "availability_domains" {
  compartment_id = var.tenancy_ocid
}

data "oci_identity_region_subscriptions" "region_subscriptions" {
  tenancy_id = var.tenancy_ocid
  filter {
    name   = "region_name"
    values = [var.region]
  }
}

data "oci_core_services" "services" {
  filter {
    name   = "name"
    values = [".*Oracle.*Services.*Network"]
    regex  = true
  }
}

data "oci_core_images" "worker" {
  compartment_id = var.compartment_ocid
  display_name   = "ffmpeg_worker"
  sort_by        = "TIMECREATED"
  sort_order     = "DESC"
}
