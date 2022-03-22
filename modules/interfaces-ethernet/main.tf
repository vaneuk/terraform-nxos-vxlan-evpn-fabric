locals {

  # interfaces = var.model["interfaces"]["ethernet"]
  interfaces = { for interface_name, interface in var.model["interfaces"]["ethernet"] :
    interface_name => merge(interface, var.model["interfaces"]["templates"][var.model["interfaces"]["ethernet"][interface_name]["template"]])
  }
  # interfaces = {for k, v in lookup(var.model, "ospf", {}) : k => v }
  # ospfs = {for k, v in lookup(var.model, "ospf", {}) : k => v if contains(v.apply_to, var.hostname)}
}

# output "ospf" {
#   value = local.ospfs
# }

# module "nxos_ospf" {
#   source   = "../../../terraform-nxac/modules/nxos-ospf2"
#   for_each = local.ospfs
#   name     = each.key
#   # vrf                      = lookup(each.value, "vrf", "default")
#   vrfs = each.value.vrfs
#   # router_id                = lookup(each.value, "router_id", null)
#   # adjancency_logging_level = lookup(each.value, "adjancency_logging_level", "none")
# }


module "nxos_ethernet_interface" {
  source      = "../../modules-core/nxos-ethernet-interface"
  for_each    = local.interfaces
  # for_each    = { for iface in lookup(lookup(var.nexus, "interfaces", {}), "ethernet", []) : iface.id => iface }
  id          = each.key
  description = lookup(each.value, "description", "")
  ip_address  = lookup(each.value, "ip_address", null)
  vrf         = lookup(each.value, "vrf", "default")
  mode        = lookup(each.value, "mode", "access")
  layer       = lookup(each.value, "layer", "Layer2")
  # layer       = lookup(each.value, "layer", null) != null ? each.value.layer : lookup(each.value, "ip_address", null) != null ? "Layer3" : null
  state       = lookup(each.value, "state", "up")
  speed       = lookup(each.value, "speed", "auto")
  mtu         = lookup(each.value, "mtu", 1500)
  debounce = lookup(each.value, "debounce", 100)
}
