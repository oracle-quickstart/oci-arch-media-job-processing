variable "availability_domain" {
  type        = string
  description = "Availability Domain used for the Oracle-OCI builder."
}

variable "ol_base_image_ocid" {
  type        = string
  description = "Base image used for the Oracle-OCI builder."
}

variable "compartment_ocid" {
  type        = string
  description = "Compartment used for the Oracle-OCI builder."
}

variable "fingerprint" {
  type        = string
  description = "Authentication key fingerprint used for the Oracle-OCI builder."
}

variable "key_file" {
  type        = string
  description = "Authentication key used for the Oracle-OCI builder."
}

variable "region" {
  type        = string
  description = "Region used for the Oracle-OCI builder."
}

variable "subnet_ocid" {
  type        = string
  description = "Subnet used for the Oracle-OCI builder."
}

variable "tenancy_ocid" {
  type        = string
  description = "Tenancy used for the Oracle-OCI builder."
}

variable "user_ocid" {
  type        = string
  description = "User used for the Oracle-OCI builder."
}


source "oracle-oci" "ffmpeg" {
  availability_domain = var.availability_domain
  base_image_ocid     = var.ol_base_image_ocid
  compartment_ocid    = var.compartment_ocid
  fingerprint         = var.fingerprint
  image_name          = "ffmpeg_worker"
  key_file            = var.key_file
  region              = var.region
  shape               = "VM.Standard2.2"
  ssh_username        = "opc"
  subnet_ocid         = var.subnet_ocid
  tenancy_ocid        = var.tenancy_ocid
  user_ocid           = var.user_ocid

  tags = {
    BuildVersion = "1.0"
    BuildProject = "MediaTranscode"
  }
}

build {
  sources = ["source.oracle-oci.ffmpeg"]

  #provisioner "file" {
  #  destination = "/home/opc/101-oracle-cloud-agent-run-command"
  #  source      = "oracle-cloud-agent-run"
  #}

  #provisioner "shell" {
  #  inline = [
  #    "sudo chown root:root /home/opc/101-oracle-cloud-agent-run-command",
  #    "sudo mv /home/opc/101-oracle-cloud-agent-run-command /etc/sudoers.d/101-oracle-cloud-agent-run-command",
  #    "sudo chmod 0440 /etc/sudoers.d/101-oracle-cloud-agent-run-command"
  #  ]
  #}

  provisioner "file" {
    destination = "/home/opc/transcode.service"
    source      = "transcode.service"
  }

  provisioner "file" {
    destination = "/home/opc/transcode.sh"
    source      = "transcode.sh"
  }

  provisioner "shell" {
    inline = [
      "sudo yum install -y policycoreutils-python-utils",
      "mkdir /home/opc/logs",
      "chmod +x /home/opc/transcode.sh",
      "sudo semanage fcontext -a -t bin_t /home/opc/transcode.sh",
      "sudo restorecon /home/opc/transcode.sh",
      "chmod 644 /home/opc/transcode.service",
      "sudo mv /home/opc/transcode.service /etc/systemd/system/transcode.service",
      "sudo chown root:root /etc/systemd/system/transcode.service",
      "sudo semanage fcontext -a -t systemd_unit_file_t /usr/lib/systemd/system/transcode.service",
      "sudo restorecon /etc/systemd/system/transcode.service",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable transcode.service"
    ]
  }

#  provisioner "shell" {
#    inline = [
#      "wget https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh -O oci_cli_install.sh",
#      "bash oci_cli_install.sh --accept-all-defaults"
#    ]
#  }

  provisioner "shell" {
    inline = [
      "sudo dnf -y install oraclelinux-developer-release-el8",
      "sudo dnf -y install python36-oci-cli"
    ]
  }

  provisioner "file" {
    destination = "/home/opc/compile-ffmpeg.sh"
    source      = "compile-ffmpeg.sh"
  }

  provisioner "shell" {
    script = "compile-ffmpeg.sh"
  }
}
