## Copyright © 2021, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_core_vcn" "vcn" {
  cidr_block     = var.vcn_cidr
  dns_label      = "jobs"
  compartment_id = var.compartment_ocid
  display_name   = "vcn"
  defined_tags   = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}

resource "oci_core_security_list" "public_security_list" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "public_subnets"
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "6"
  }
  ingress_security_rules {
    protocol  = "6" // tcp
    source    = "0.0.0.0/0"
    stateless = false

    tcp_options {
      min = 443
      max = 443
    }
  }
  defined_tags = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}

resource "oci_core_security_list" "private_security_list" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "private_subnets"
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "6"
  }
  defined_tags = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}

resource "oci_core_subnet" "public_subnet" {
  cidr_block        = var.public_subnet_cidr
  display_name      = "public_subnet"
  dns_label         = "public"
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.vcn.id
  security_list_ids = [oci_core_security_list.public_security_list.id]
  route_table_id    = oci_core_route_table.public_subnets.id
  dhcp_options_id   = oci_core_vcn.vcn.default_dhcp_options_id
  defined_tags      = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}


resource "oci_core_subnet" "private_subnet" {
  cidr_block                 = var.private_subnet_cidr
  display_name               = "private_subnet"
  dns_label                  = "private"
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.vcn.id
  prohibit_public_ip_on_vnic = "true"
  security_list_ids          = [oci_core_security_list.private_security_list.id]
  route_table_id             = oci_core_route_table.private_subnets.id
  dhcp_options_id            = oci_core_vcn.vcn.default_dhcp_options_id
  defined_tags               = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}

resource "oci_core_internet_gateway" "igw01" {
  compartment_id = var.compartment_ocid
  display_name   = "igw01"
  vcn_id         = oci_core_vcn.vcn.id
  defined_tags   = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}

resource "oci_core_service_gateway" "sgw01" {
  compartment_id = var.compartment_ocid
  display_name   = "sgw01"
  vcn_id         = oci_core_vcn.vcn.id
  services {
    service_id = lookup(data.oci_core_services.services.services[0], "id")
  }
  defined_tags = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}

resource "oci_core_route_table" "public_subnets" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "public_subnets"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.igw01.id
  }
  defined_tags = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}

resource "oci_core_route_table" "private_subnets" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "private_subnets"
  route_rules {
    destination       = lookup(data.oci_core_services.services.services[0], "cidr_block")
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.sgw01.id
  }
  defined_tags = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}
