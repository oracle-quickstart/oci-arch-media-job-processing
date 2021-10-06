## Copyright © 2021, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_artifacts_container_repository" "create_job" {
  compartment_id = var.compartment_ocid
  display_name   = "create_job"
  is_public      = "false"
}
resource "oci_artifacts_container_repository" "launch_worker" {
  compartment_id = var.compartment_ocid
  display_name   = "launch_worker"
  is_public      = "false"
}
resource "oci_artifacts_container_repository" "check_preempted_worker" {
  compartment_id = var.compartment_ocid
  display_name   = "check_preempted_worker"
  is_public      = "false"
}
resource "oci_artifacts_container_repository" "retry_queued" {
  compartment_id = var.compartment_ocid
  display_name   = "retry_queued"
  is_public      = "false"
}

locals {
  ocir_docker_repository = join("", [lower(data.oci_identity_region_subscriptions.region_subscriptions.region_subscriptions[0].region_key), ".ocir.io"])
}

resource "null_resource" "docker_login" {
  depends_on = [oci_artifacts_container_repository.create_job, oci_artifacts_container_repository.launch_worker, oci_artifacts_container_repository.check_preempted_worker, oci_artifacts_container_repository.retry_queued]
  triggers = {
    create_job_function_version             = var.create_job_function_version
    launch_worker_function_version          = var.launch_worker_function_version
    check_preempted_worker_function_version = var.check_preempted_worker_function_version
    retry_queued_function_version           = var.retry_queued_function_version
  }
  provisioner "local-exec" {
    command = "echo '${var.ocir_password}' |  docker login ${local.ocir_docker_repository} --username ${data.oci_objectstorage_namespace.tenancy_namespace.namespace}/${var.ocir_user_name} --password-stdin"
  }
}

resource "null_resource" "create_job_fn_setup" {

  depends_on = [null_resource.docker_login]
  triggers = {
    function_version = var.create_job_function_version
  }

  provisioner "local-exec" {
    command     = "image=$(docker images | grep create_job | awk -F ' ' '{print $3}') ; docker rmi -f $image &> /dev/null ; echo $image"
    working_dir = "functions/create_job"
  }

  provisioner "local-exec" {
    command     = "fn build"
    working_dir = "functions/create_job"
  }
  provisioner "local-exec" {
    command     = "image=$(docker images | grep create_job | grep ${var.create_job_function_version} | awk -F ' ' '{print $3}') ; docker tag $image ${local.ocir_docker_repository}/${data.oci_objectstorage_namespace.tenancy_namespace.namespace}/create_job:${var.create_job_function_version}"
    working_dir = "functions/create_job"
  }

  provisioner "local-exec" {
    command     = "docker push ${local.ocir_docker_repository}/${data.oci_objectstorage_namespace.tenancy_namespace.namespace}/create_job:${var.create_job_function_version}"
    working_dir = "functions/create_job"
  }

}
resource "null_resource" "launch_worker_fn_setup" {

  depends_on = [null_resource.docker_login]

  triggers = {
    function_version = var.launch_worker_function_version
  }

  provisioner "local-exec" {
    command     = "image=$(docker images | grep launch_worker | awk -F ' ' '{print $3}') ; docker rmi -f $image &> /dev/null ; echo $image"
    working_dir = "functions/launch_worker"
  }

  provisioner "local-exec" {
    command     = "fn build"
    working_dir = "functions/launch_worker"
  }

  provisioner "local-exec" {
    command     = "image=$(docker images | grep launch_worker | awk -F ' ' '{print $3}') ; docker tag $image ${local.ocir_docker_repository}/${data.oci_objectstorage_namespace.tenancy_namespace.namespace}/launch_worker:${var.launch_worker_function_version}"
    working_dir = "functions/launch_worker"
  }

  provisioner "local-exec" {
    command     = "docker push ${local.ocir_docker_repository}/${data.oci_objectstorage_namespace.tenancy_namespace.namespace}/launch_worker:${var.launch_worker_function_version}"
    working_dir = "functions/launch_worker"
  }
}

resource "null_resource" "check_preempted_worker_fn_setup" {

  depends_on = [null_resource.docker_login]

  triggers = {
    function_version = var.check_preempted_worker_function_version
  }
  provisioner "local-exec" {
    command     = "image=$(docker images | grep check_preempted_worker | awk -F ' ' '{print $3}') ; docker rmi -f $image &> /dev/null ; echo $image"
    working_dir = "functions/check_preempted_worker"
  }

  provisioner "local-exec" {
    command     = "fn build"
    working_dir = "functions/check_preempted_worker"
  }

  provisioner "local-exec" {
    command     = "image=$(docker images | grep check_preempted_worker | awk -F ' ' '{print $3}') ; docker tag $image ${local.ocir_docker_repository}/${data.oci_objectstorage_namespace.tenancy_namespace.namespace}/check_preempted_worker:${var.check_preempted_worker_function_version}"
    working_dir = "functions/check_preempted_worker"
  }

  provisioner "local-exec" {
    command     = "docker push ${local.ocir_docker_repository}/${data.oci_objectstorage_namespace.tenancy_namespace.namespace}/check_preempted_worker:${var.check_preempted_worker_function_version}"
    working_dir = "functions/check_preempted_worker"
  }
}

resource "null_resource" "retry_queued_fn_setup" {

  depends_on = [null_resource.docker_login]

  triggers = {
    function_version = var.retry_queued_function_version
  }

  provisioner "local-exec" {
    command     = "image=$(docker images | grep retry_queued | awk -F ' ' '{print $3}') ; docker rmi -f $image &> /dev/null ; echo $image"
    working_dir = "functions/retry_queued"
  }

  provisioner "local-exec" {
    command     = "fn build"
    working_dir = "functions/retry_queued"
  }

  provisioner "local-exec" {
    command     = "image=$(docker images | grep retry_queued | awk -F ' ' '{print $3}') ; docker tag $image ${local.ocir_docker_repository}/${data.oci_objectstorage_namespace.tenancy_namespace.namespace}/retry_queued:${var.retry_queued_function_version}"
    working_dir = "functions/retry_queued"
  }

  provisioner "local-exec" {
    command     = "docker push ${local.ocir_docker_repository}/${data.oci_objectstorage_namespace.tenancy_namespace.namespace}/retry_queued:${var.retry_queued_function_version}"
    working_dir = "functions/retry_queued"
  }
}


