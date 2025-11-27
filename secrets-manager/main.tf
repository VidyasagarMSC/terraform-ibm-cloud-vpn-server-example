data "ibm_resource_group" "group" {
  name = "Default"
}

data "ibm_resource_instance" "pre-created-secmgr" {
  count    = var.pre-create-secmgr-name == "" ? 0 : 1
  name     = var.pre-create-secmgr-name
  location = var.region_name
  service  = "secrets-manager"
}

resource "ibm_resource_instance" "sec_mgr" {
  count             = var.pre-create-secmgr-name == "" ? 1 : 0
  name              = "vpc-secmgr"
  service           = "secrets-manager"
  plan              = var.service_plan
  location          = var.region_name
  resource_group_id = data.ibm_resource_group.group.id
  parameters = {
    "allowed_network" = "public-and-private"  # ← This is CORRECT for Secrets Manager
  }

  //User can increase timeouts
  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}

locals {
  sec_mgr_id = var.pre-create-secmgr-name == "" ? ibm_resource_instance.sec_mgr[0].guid : data.ibm_resource_instance.pre-created-secmgr[0].guid
}

resource "ibm_sm_secret_group" "sm_secret_group" {
  instance_id = local.sec_mgr_id
  region      = var.region_name
  name        = "vpc-sec-group"
  description = "default secret group"
}

output "import_cert_server_crn" {
  value = ibm_sm_imported_certificate.sm_imported_certificate_server.crn
}

output "import_cert_client_crn" {
  value = ibm_sm_imported_certificate.sm_imported_certificate_client.crn
}
