# resource "nxos_rest" "ospfEntity" {
#   dn         = "sys/ospf"
#   class_name = "ospfEntity"
#   content = {
#     adminSt = "enabled"
#   }
# }

resource "nxos_rest" "bgpInst" {
  dn         = "sys/bgp/inst"
  class_name = "bgpInst"
  content = {
    asn         = var.asn
    enhancedErr = var.enhanced_error == true ? "yes" : "no"
  }
}

resource "nxos_rest" "bgpDom" {
  for_each   = var.vrfs
  dn         = "${nxos_rest.bgpInst.id}/dom-[${each.key}]"
  class_name = "bgpDom"
  content = {
    name  = each.key
    rtrId = each.value.router_id
  }
}

resource "nxos_rest" "bgpRtCtrl" {
  for_each   = var.vrfs
  dn         = "${nxos_rest.bgpDom[each.key].id}/rtctrl"
  class_name = "bgpRtCtrl"
  content = {
    logNeighborChanges = each.value.log_neighbor_changes == true ? "enabled" : "disabled"
  }
}

resource "nxos_rest" "bgpGr" {
  for_each   = var.vrfs
  dn         = "${nxos_rest.bgpDom[each.key].id}/gr"
  class_name = "bgpGr"
  content = {
    staleIntvl = each.value.gr_stalepath_time != null ? each.value.gr_stalepath_time : 300
    restartIntvl = each.value.gr_restart_time != null ? each.value.gr_restart_time : 120
  }
}


/*
Example:

template peer SPINE-PEERS
  remote-as 31411
  update-source loopback0
  address-family l2vpn evpn
    send-community
    send-community extended

this can be configured only for "vrf default", so hard coding.
*/

resource "nxos_rest" "bgpPeerCont" {
  for_each   = var.template_peers
  dn         = "${nxos_rest.bgpDom["default"].id}/peercont-[${each.key}]"
  class_name = "bgpPeerCont"
  content = {
    name  = each.key
    asn   = each.value.asn
    srcIf = each.value.source_interface
  }
}

# DEBUG
resource "null_resource" "terraform-debug-test4" {
  provisioner "local-exec" {
    command = "echo $VARIABLE1 >> debug.txt ; echo $VARIABLE2 >> debug2.txt; echo $VARIABLE3 >> debug3.txt"

    environment = {
      VARIABLE1 = jsonencode(var.template_peers)
      VARIABLE2 = jsonencode(local.template_peers_map)
      VARIABLE3 = jsonencode(var.vrfs)
    }
  }
}

locals {
  template_peers_map = merge([
    for template_name, template in var.template_peers : {
      for af_name, af in template.address_family : "${template_name}-${af_name}" => merge(af, { "template" : template_name, "address_family": af_name })
    }
  ]...)
}

resource "nxos_rest" "bgpPeerAf" {
  for_each = local.template_peers_map
  dn       = "${nxos_rest.bgpPeerCont[each.value.template].id}/af-[${each.value.address_family}]"
  # af-[l2vpn-evpn]
  # TODO: change to l2vpn_evpn ?
  class_name = "bgpPeerAf"
  content = {
    sendComStd = lookup(each.value, "send_community_standard", false) == true ? "enabled" : "disabled"
    sendComExt = lookup(each.value, "send_community_extended", false) == true ? "enabled" : "disabled"
  }
}

locals {
  neighbors_map = merge([
    for vrf_name, vrf in var.vrfs : {
      for neighbor_ip, neighbor in vrf.neighbors : "${vrf_name}-${neighbor_ip}" => merge(neighbor, { "vrf" : vrf_name, "addr": neighbor_ip })
    }
  ]...)
}

resource "nxos_rest" "bgpPeer" {
  for_each   = local.neighbors_map
  dn         = "${nxos_rest.bgpDom[each.value.vrf].id}/peer-[${each.value.addr}]"
  class_name = "bgpPeer"
  content = {
    # asn   = each.value.asn
    addr = each.value.addr
    peerImp = each.value.inherit_peer
    name = each.value.description
    # srcIf = each.value.source_interface
  }
}

# # resource "nxos_rest" "ospfArea" {
# #   for_each   = { for area in var.areas : area.id => area }
# #   dn         = "${nxos_rest.ospfDom.id}/area-[${each.value.id}]"
# #   class_name = "ospfArea"
# #   content = {
# #     id       = each.value.id
# #     authType = each.value.authentication_type != null ? each.value.authentication_type : "unspecified"

# #   }
# # }

# #  {
# #         network_key       = network_key
# #         purpose           = subnet.purpose
# #         parent_cidr_block = network.address_space[0]
# #         newbits           = subnet.newbits
# #         item              = subnet.item
# #       }

# locals {
#   interfaces_map = merge([
#     for vrf_name, vrf in var.vrfs : {
#       for interface_name, interface in vrf.interfaces : interface_name => merge(interface, { "vrf" : vrf_name })
#     }
#   ]...)
# }

# # output "interface_list" {
# #   value = local.interfaces_list
# # }

# resource "nxos_rest" "ospfIf" {
#   # for_each   = { for iface in var.interfaces : iface.id => iface }
#   for_each = local.interfaces_map
#   dn         = "${nxos_rest.ospfDom[each.value.vrf].id}/if-[${each.key}]"
#   class_name = "ospfIf"
#   content = {
#     id                   = each.key
#     area                 = each.value.area
#     advertiseSecondaries = each.value.advertise_secondaries != null ? each.value.advertise_secondaries : "yes"
#     nwT                  = each.value.network_type != null ? each.value.network_type : "unspecified"
#     cost                 = each.value.cost != null ? each.value.cost : "unspecified"
#   }
# }

# # resource "nxos_rest" "ospfAuthNewP" {
# #   for_each   = { for iface in var.interfaces : iface.id => iface if iface.md5key != null }
# #   dn         = "${nxos_rest.ospfIf[each.value.id].id}/authnew"
# #   class_name = "ospfAuthNewP"
# #   content = {
# #     keyId            = 1
# #     md5key           = "0 ${each.value.md5key}"
# #     md5keySecureMode = "no"
# #   }
# #   lifecycle {
# #     ignore_changes = [content["md5key"]]
# #   }

# # }