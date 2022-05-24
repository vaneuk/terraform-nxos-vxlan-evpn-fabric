terraform {
  required_version = ">= 1.0.0"

  required_providers {
    nxos = {
      source  = "netascode/nxos"
      version = ">= 0.3.14"
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
  url      = "https://10.0.24.200"
}

variable "hostname" {
  description = "Device hostname."
}

variable "groups" {
  description = "Device groups."
}

locals {
  # Prepare config files list
  groups             = concat(var.groups, [var.hostname])
  group_config_files = join(",", local.groups)

  # Load parameters and model
  parameters = yamldecode(data.utils_deep_merge_yaml.parameters.output)
  m          = yamldecode(data.utils_deep_merge_yaml.model.output)

  # Map of L2VNI applied to this device
  l2vni_map = {
    for service_name, service in lookup(local.m, "l2vni", {}) : service_name => service if length(setintersection(toset(service.apply_to), toset(local.groups))) > 0
  }

  # Create VRF map
  vrfs_set = toset([for service_name, service in local.l2vni_map : service.vrf])
  vrfs     = { for vrf_name in local.vrfs_set : vrf_name => merge(local.m.l3vni[vrf_name], local.m.vrf_templates.auto) }

  vlans = [for service_name, service in local.l2vni_map :
    {
      "id" : service.vlan
      "name" : service_name
    }
  ]

  interfaces_vlan_l2vni = [for service_name, service in local.l2vni_map :
    merge(service,
      {
        "id" : service.vlan
        "description" : service_name
      }
    )
  ]
  interfaces_vlan_l3vni = [for vrf_name, vrf in local.vrfs :
    {
      "id" : vrf.vlan
      "description" : lookup(vrf, "description", null)
      "mtu" : lookup(vrf, "mtu", 9216)
      "ip_forward" : true
      "vrf" : vrf_name
    }
  ]
  interfaces_vlan = concat(local.interfaces_vlan_l2vni, local.interfaces_vlan_l3vni)

  # Update Template if required
  interfaces_ethernet = {
    for interface_name, interface in local.m.interfaces_ethernet :
    interface_name => contains(keys(interface), "template") ? merge(interface, local.m.interface_templates[interface.template]) : interface
  }

  # Update model
  model = merge(
    local.m,
    { "hostname" = var.hostname },
    { "features" = [for k, v in local.m.features : k if v] },
    { "vrfs" = local.vrfs },
    { "vlans" = local.vlans },
    { "interfaces_ethernet" = local.interfaces_ethernet },
    { "interfaces_vlan" = local.interfaces_vlan },
    { "foo" = local.interfaces_vlan },
  )

  # Load final model
  model_nxos = jsondecode(data.external.nxos_model.result.model)
}

data "utils_deep_merge_yaml" "parameters" {
  append_list = true
  input = concat(
    [for file in fileset(path.module, "../../parameters/all/*.yaml") : file(file)],
    [for file in fileset(path.module, "../../parameters/groups/{${local.group_config_files}}.yaml") : file(file)],
  )
}

data "utils_deep_merge_yaml" "model" {
  append_list = true
  input = concat(
    [for file in fileset(path.module, "../../templates/all/*.yaml") : templatefile(file, { p = local.parameters })],
    [for file in fileset(path.module, "../../templates/groups/{${local.group_config_files}}.yaml") : templatefile(file, { p = local.parameters })],
    [for file in fileset(path.module, "../../templates/overlay-services/*.yaml") : templatefile(file, { p = local.parameters })],
  )
}

output "model_nxos" {
  value = local.model_nxos
}

output "model" {
  value = local.model
}

data "external" "nxos_model" {
  program = ["python3", "fm.py"]
  query = {
    model = jsonencode(local.model)
  }
}

module "nxos_config" {
  # source  = "netascode/config/nxos"
  # version = ">= 0.0.1"
  source = "../../../terraform-nxos/terraform-nxos-config/"

  model = local.model_nxos
}
