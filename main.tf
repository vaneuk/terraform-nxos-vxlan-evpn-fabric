terraform {
  required_version = ">= 1.0.0"

  required_providers {
    nxos = {
      source  = "netascode/nxos"
      version = ">= 0.3.16"
    }
    utils = {
      source  = "cloudposse/utils"
      version = ">= 0.15.0"
    }
  }
  experiments = [module_variable_optional_attrs]
}

provider "nxos" {
  username = "admin"
  password = "cisco!123"
  devices  = local.devices
  # url = "https://10.0.24.200"
}

locals {
  devices = yamldecode(file("inventory.yaml"))
  models  = { for device in local.devices : device.name => yamldecode(file("${path.module}/configs/${device.name}.yaml")) }
}

module "nxos_config" {
  # source  = "netascode/config/nxos"
  # version = ">= 0.0.1"
  for_each = local.models
  source   = "../terraform-nxos/terraform-nxos-config/"

  model  = each.value
  device = each.key
}
