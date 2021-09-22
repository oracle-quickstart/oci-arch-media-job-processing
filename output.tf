output "upload_objects_to" {
  value = join("", ["https://console.", var.region, ".oraclecloud.com/object-storage/buckets/", data.oci_objectstorage_namespace.tenancy_namespace.namespace, "/", oci_objectstorage_bucket.source_bucket.name, "/objects"])
}