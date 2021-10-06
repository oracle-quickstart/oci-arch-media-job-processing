## Copyright © 2021, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_apigateway_gateway" "job_management" {
  compartment_id = var.compartment_ocid
  display_name   = "job_management"
  endpoint_type  = "PUBLIC"
  response_cache_details {
    type = "NONE"
  }
  subnet_id    = oci_core_subnet.public_subnet.id
  defined_tags = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
}

resource "oci_apigateway_deployment" "job_management" {
  compartment_id = var.compartment_ocid
  display_name   = "job_management"

  gateway_id  = oci_apigateway_gateway.job_management.id
  path_prefix = "/job_management"
  specification {
    logging_policies {
      execution_log {
        is_enabled = "true"
        log_level  = "INFO"
      }
    }
    routes {
      backend {
        function_id = oci_functions_function.retry_queued.id
        type        = "ORACLE_FUNCTIONS_BACKEND"
      }
      logging_policies {
        execution_log {
          is_enabled = "true"
          log_level  = "INFO"
        }
      }
      methods = [
        "ANY",
      ]
      path = "/retry_queued"
    }
  }
}
resource "oci_health_checks_http_monitor" "retry_queued" {
  compartment_id = var.compartment_ocid
  display_name   = "retry_queued"

  interval_in_seconds = "900"
  is_enabled          = "true"
  method              = "GET"
  path                = join("", [oci_apigateway_deployment.job_management.path_prefix, oci_apigateway_deployment.job_management.specification[0].routes[0].path])
  port                = "443"
  protocol            = "HTTPS"
  targets = [
    oci_apigateway_gateway.job_management.ip_addresses[0].ip_address,
  ]
  timeout_in_seconds = "30"
  vantage_point_names = [
    "aws-iad",
  ]
}
