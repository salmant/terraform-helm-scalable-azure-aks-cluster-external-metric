
locals {
  common_tags = {
    Project           = "${var.project}"  
    Department        = "${var.department}"  
    Team              = "${var.team}"
    Environment       = "${var.stage}"
    KubernetesVersion = "${var.kubernetes_version}"
    CreatedBy         = "Terraform"
  }
}

