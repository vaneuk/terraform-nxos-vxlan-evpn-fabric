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
  experiments = [module_variable_optional_attrs]
}

provider "nxos" {
  username = "admin"
  password = "Admin_1234!"
  # url      = "https://10.62.130.39"
  url = "https://sandbox-nxos-1.cisco.com"
  # url      = "https://10.62.130.36"
  retries = 1
}

variable "hostname" {
  description = "device hostname"
}

variable "groups" {
  description = "device groups"
}

locals {
  model = yamldecode(data.utils_deep_merge_yaml.model.output)
  # leaf_data = [for file in fileset(path.module, "../../data/groups/${var.hostname}.yaml") : file(file)]
  # leaf_data = [for file in fileset(path.module, "../../data/groups/${var.hostname}.yaml") : file(file)]
  groups_and_hostname = concat(var.groups, [var.hostname])
  group_config_files = join(",", local.groups_and_hostname)
  group_data = [for file in fileset(path.module, "../../data/groups/{${local.group_config_files}}.yaml") : file(file)]
  # group_data = flatten([
  #   for group in var.groups: [
  #     for file in fileset(path.module, "../../data/groups/${group}.yaml") : file(file)
  #   ]
  # ])
  # qwe = [for file in fileset(path.module, "../../data/all/*.yaml") : file(file)]
}

# output "group" {
#   value = local.group_data
# }

# output "leaf" {
#   value = local.leaf_data
# }

# output "all_data" {
#   value = local.qwe
# }

output "all_groups" {
  value = local.group_config_files
}

data "utils_deep_merge_yaml" "model" {
  append_list = true
  input       = concat(
    [for file in fileset(path.module, "../../data/all/*.yaml") : file(file)],
    [for file in fileset(path.module, "../../data/groups/{${local.group_config_files}}.yaml") : file(file)],
    # local.group_data,
    # [for file in fileset(path.module, "../../data/${var.hostname}/*.yaml") : file(file)],
    # local.leaf_data,
    [for file in fileset(path.module, "../../data/overlay-services/*.yaml") : file(file)]
    )
  # input       = concat([for file in fileset(path.module, "data/*.yaml") : file(file)], [file("${path.module}/defaults/defaults.yaml")])
}

module "vrf" {
  source   = "../../modules/vrf"
  model    = local.model
  groups = local.groups_and_hostname
}

module "interfaces-ethernet" {
  source      = "../../modules/interfaces-ethernet"
  model    = local.model
  # depends_on = [module.vrfs]
}

output "model" {
  value = local.model
}

module "ospf" {
  source     = "../../modules/ospf"
  model      = local.model
  hostname   = var.hostname
  depends_on = [module.interfaces-ethernet]
}

module "bgp" {
  source     = "../../modules/bgp"
  model      = local.model
  depends_on = [module.ospf]
}

# module "nxos_vrf" {
#   source     = "../../../terraform-nxac/modules/nxos-vrf"
#   for_each   = {
#     for vrf in lookup(local.model, "vrfs", []) : vrf.name => vrf
#     if contains(vrf.nodes, var.node)
#     }
#   name       = each.value.name
#   # depends_on = [module.nxos_vrf_default]
# }

# module "vrf" {
#   source = "./modules/vrf"

#   for_each    = toset([for tenant in lookup(local.model, "vrfs", []) : vrf.name])
#   model       = local.model
#   vrf_name = each.value
# }

