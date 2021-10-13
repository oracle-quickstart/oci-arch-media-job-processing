## Copyright © 2021, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_nosql_table" "job_tracking" {
  compartment_id      = var.compartment_ocid
  ddl_statement       = "CREATE TABLE job_tracking(event_id STRING, object_name STRING, status STRING, instance_id STRING, Capacity STRING, PRIMARY KEY(SHARD(event_id))) USING TTL 1 DAYS"
  is_auto_reclaimable = "false"
  name                = "job_tracking"
  table_limits {
    max_read_units     = "100"
    max_storage_in_gbs = "1"
    max_write_units    = "100"
  }
  defined_tags = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}

