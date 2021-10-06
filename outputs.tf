## Copyright © 2021, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

output "upload_objects_to" {
  value = join("", ["https://console.", var.region, ".oraclecloud.com/object-storage/buckets/", data.oci_objectstorage_namespace.tenancy_namespace.namespace, "/", oci_objectstorage_bucket.source_bucket.name, "/objects"])
}

