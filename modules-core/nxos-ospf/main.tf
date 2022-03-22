resource "nxos_rest" "ospfEntity" {
  dn         = "sys/ospf"
  class_name = "ospfEntity"
  content = {
    adminSt = "enabled"
  }
}

resource "nxos_rest" "ospfInst" {
  # dn         = "sys/ospf/inst-[${var.name}]"
  dn         = "${nxos_rest.ospfEntity.id}/inst-[${var.name}]"
  class_name = "ospfInst"
  content = {
    name = var.name
  }
}

resource "nxos_rest" "ospfDom" {
  for_each   = var.vrfs
  dn         = "${nxos_rest.ospfInst.id}/dom-[${each.key}]"
  class_name = "ospfDom"
  content = {
    name              = each.key
    rtrId             = each.value.router_id
    adjChangeLogLevel = each.value.adjancency_logging_level
  }
}

# resource "nxos_rest" "ospfArea" {
#   for_each   = { for area in var.areas : area.id => area }
#   dn         = "${nxos_rest.ospfDom.id}/area-[${each.value.id}]"
#   class_name = "ospfArea"
#   content = {
#     id       = each.value.id
#     authType = each.value.authentication_type != null ? each.value.authentication_type : "unspecified"

#   }
# }

#  {
#         network_key       = network_key
#         purpose           = subnet.purpose
#         parent_cidr_block = network.address_space[0]
#         newbits           = subnet.newbits
#         item              = subnet.item
#       }

locals {
  interfaces_map = merge([
    for vrf_name, vrf in var.vrfs : {
      for interface_name, interface in vrf.interfaces : interface_name => merge(interface, { "vrf" : vrf_name })
    }
  ]...)
}

# output "interface_list" {
#   value = local.interfaces_list
# }

resource "nxos_rest" "ospfIf" {
  # for_each   = { for iface in var.interfaces : iface.id => iface }
  for_each = local.interfaces_map
  dn         = "${nxos_rest.ospfDom[each.value.vrf].id}/if-[${each.key}]"
  class_name = "ospfIf"
  content = {
    id                   = each.key
    area                 = each.value.area
    advertiseSecondaries = each.value.advertise_secondaries != null ? each.value.advertise_secondaries : "yes"
    nwT                  = each.value.network_type != null ? each.value.network_type : "unspecified"
    cost                 = each.value.cost != null ? each.value.cost : "unspecified"
  }
}

# resource "nxos_rest" "ospfAuthNewP" {
#   for_each   = { for iface in var.interfaces : iface.id => iface if iface.md5key != null }
#   dn         = "${nxos_rest.ospfIf[each.value.id].id}/authnew"
#   class_name = "ospfAuthNewP"
#   content = {
#     keyId            = 1
#     md5key           = "0 ${each.value.md5key}"
#     md5keySecureMode = "no"
#   }
#   lifecycle {
#     ignore_changes = [content["md5key"]]
#   }

# }