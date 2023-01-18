resource "random_string" "uniquer" {
  length  = 5
  special = false
  numeric  = true
  lower   = false
  upper   = false
}

locals {
  uniquer             = var.uniquer != null ? var.uniquer : "${random_string.uniquer.id}"
  resources_prefix    = var.resources_prefix != null ? var.resources_prefix : "${local._default.name_prefix}-${local.uniquer}"
  location            = var.location
  resource_group_name = "${local.resources_prefix}-rg"

  vm_user                                   = var.vm_user != null ? var.vm_user : "${local._secrets.vm_user}"
  vm_user_password                          = var.vm_user_password != null ? var.vm_user_password : "${local._secrets.vm_user_password}"
  key_vault_name                            = "${local.resources_prefix}-kv"
  virtual_machine_name                      = "${local.resources_prefix}-vm"
  virtual_network                           = "${local.resources_prefix}-network"
  virtual_network_nic                       = "${local.resources_prefix}-nic"
  network_security_group                    = "${local.resources_prefix}-nsg"
  public_ip                                 = "${local.resources_prefix}-ip"
  os_disk                                   = "${local.resources_prefix}-disk"
  bastion_name                              = "${local.resources_prefix}-bashub"
}