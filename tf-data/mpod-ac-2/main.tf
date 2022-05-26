terraform {
  required_version = ">= 1.0.0"

  required_providers {
    nxos = {
      source  = "netascode/nxos"
      version = ">= 0.1.1"
    }
    utils = {
      source  = "cloudposse/utils"
      version = ">= 0.15.0"
    }
  }
}

provider "nxos" {
  username = "admin"
  password = "Admin_1234!"
  # url      = "https://10.62.130.39"
  url = "https://sandbox-nxos-1.cisco.com"
  # url      = "https://10.62.130.40"
  retries = 1
}

locals {
  model = yamldecode(data.utils_deep_merge_yaml.model.output)
}

data "utils_deep_merge_yaml" "model" {
  append_list = true
  input       = concat([for file in fileset(path.module, "../../data/*.yaml") : file(file)])
  # input       = concat([for file in fileset(path.module, "data/*.yaml") : file(file)], [file("${path.module}/defaults/defaults.yaml")])
}

module "nxos_vrf" {
  source   = "../../../terraform-nxac/modules/nxos-vrf"
  for_each = { for vrf in lookup(local.model, "vrfs", []) : vrf.name => vrf }
  name     = each.value.name
  # depends_on = [module.nxos_vrf_default]
}

# module "vrf" {
#   source = "./modules/vrf"

#   for_each    = toset([for tenant in lookup(local.model, "vrfs", []) : vrf.name])
#   model       = local.model
#   vrf_name = each.value
# }