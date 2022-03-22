resource "nxos_rest" "l3Inst" {
  dn         = "sys/inst-${var.name}"
  class_name = "l3Inst"
  content = {
    name  = var.name
    encap = var.vni != null ? "vxlan-${var.vni}" : "unknown"
  }
}

locals {
  rd_none = var.rd == null ? true : false
  rd_auto = var.rd == "auto" ? true : false
  rd_ipv4 = can(regex("\\.", var.rd)) ? true : false
  rd_as2  = !can(regex("\\.", var.rd)) && can(regex(":", var.rd)) ? (tonumber(split(":", var.rd)[0]) <= 65535 ? true : false) : false
  rd_as4  = !can(regex("\\.", var.rd)) && can(regex(":", var.rd)) ? (tonumber(split(":", var.rd)[0]) >= 65536 ? true : false) : false
  rd_modified = local.rd_none ? "unknown:unknown:0:0" : (
    local.rd_auto ? "rd:unknown:0:0" : (
      local.rd_ipv4 ? "rd:ipv4-nn2:${var.rd}" : (
        local.rd_as2 ? "rd:as2-nn2:${var.rd}" : (
          local.rd_as4 ? "rd:as4-nn2:${var.rd}" : "unexpected_rd_format"
  ))))
}

module "nxos-rd-rt-format-rd" {
  source = "./nxos-rd-rt-format/"

  value = var.rd
  rd = true
}

resource "nxos_rest" "rtctrlDom" {
  dn         = "${nxos_rest.l3Inst.id}/dom-${var.name}"
  class_name = "rtctrlDom"
  content = {
    name = var.name
    rd = module.nxos-rd-rt-format-rd.result
  }
}

# DEBUG
# resource "null_resource" "blah" {
#   provisioner "local-exec" {
#     command = "echo $VARIABLE1 >> debug.json"

#     environment = {
#       VARIABLE1 = jsonencode(module.rd_rt_compute.result)
#     }
#   }
# }


locals {
  ipv4_unicast_rt_import = var.ipv4_unicast_rt_both_auto ? concat(["route-target:unknown:0:0"], var.ipv4_unicast_rt_import) : var.ipv4_unicast_rt_import


  ipv4_import_ipv4 = var.ipv4_unicast_rt_both_auto || length(var.ipv4_unicast_rt_import) > 0
  ipv4_import_evpn = var.ipv4_unicast_rt_both_auto_evpn || length(var.ipv4_unicast_rt_import_evpn) > 0
  ipv4_import = local.ipv4_import_ipv4 || local.ipv4_import_evpn
  ipv6_import_ipv6 = var.ipv6_unicast_rt_both_auto || length(var.ipv6_unicast_rt_import) > 0
  ipv6_import_evpn = var.ipv6_unicast_rt_both_auto_evpn || length(var.ipv6_unicast_rt_import_evpn) > 0
  ipv6_import = local.ipv6_import_ipv6 || local.ipv6_import_evpn
  ipv4_export_ipv4 = var.ipv4_unicast_rt_both_auto || length(var.ipv4_unicast_rt_export) > 0
  ipv4_export_evpn = var.ipv4_unicast_rt_both_auto_evpn || length(var.ipv4_unicast_rt_export_evpn) > 0
  ipv4_export = local.ipv4_export_ipv4 || local.ipv4_export_evpn
  ipv6_export_ipv6 = var.ipv6_unicast_rt_both_auto || length(var.ipv6_unicast_rt_export) > 0
  ipv6_export_evpn = var.ipv6_unicast_rt_both_auto_evpn || length(var.ipv6_unicast_rt_export_evpn) > 0
  ipv6_export = local.ipv6_export_ipv6 || local.ipv6_export_evpn
}

# address family ipv4 unicast

resource "nxos_rest" "rtctrlDomAf-ipv4-ucast" {
  count = var.ipv4_unicast ? 1 : 0
  dn         = "${nxos_rest.rtctrlDom.id}/af-ipv4-ucast"
  class_name = "rtctrlDomAf"
  content = {
    type = "ipv4-ucast"
  }
}

resource "nxos_rest" "rtctrlAfCtrl-ipv4-ucast-ipv4-ucast" {
  count = local.ipv4_import_ipv4 || local.ipv4_export_ipv4 ? 1 : 0
  dn         = "${nxos_rest.rtctrlDomAf-ipv4-ucast[0].id}/ctrl-ipv4-ucast"
  class_name = "rtctrlAfCtrl"
  content = {
    type = "ipv4-ucast"
  }
}

resource "nxos_rest" "rtctrlAfCtrl-ipv4-ucast-l2vpn-evpn" {
  count = local.ipv4_import_evpn || local.ipv4_export_evpn ? 1 : 0
  dn         = "${nxos_rest.rtctrlDomAf-ipv4-ucast[0].id}/ctrl-l2vpn-evpn"
  class_name = "rtctrlAfCtrl"
  content = {
    type = "l2vpn-evpn"
  }
}

resource "nxos_rest" "rtctrlRttP-ipv4-ucast-ipv4-ucast-import" {
  count = local.ipv4_import_ipv4 ? 1 : 0
  dn         = "${nxos_rest.rtctrlAfCtrl-ipv4-ucast-ipv4-ucast[0].id}/rttp-import"
  class_name = "rtctrlRttP"
  content = {
    type = "import"
  }
}

resource "nxos_rest" "rtctrlRttP-ipv4-ucast-ipv4-ucast-export" {
  count = local.ipv4_export_ipv4 ? 1 : 0
  dn         = "${nxos_rest.rtctrlAfCtrl-ipv4-ucast-ipv4-ucast[0].id}/rttp-export"
  class_name = "rtctrlRttP"
  content = {
    type = "export"
  }
}

resource "nxos_rest" "rtctrlRttP-ipv4-ucast-l2vpn-evpn-import" {
  count = local.ipv4_import_evpn ? 1 : 0
  dn         = "${nxos_rest.rtctrlAfCtrl-ipv4-ucast-l2vpn-evpn[0].id}/rttp-import"
  class_name = "rtctrlRttP"
  content = {
    type = "import"
  }
}

resource "nxos_rest" "rtctrlRttP-ipv4-ucast-l2vpn-evpn-export" {
  count = local.ipv4_export_evpn ? 1 : 0
  dn         = "${nxos_rest.rtctrlAfCtrl-ipv4-ucast-l2vpn-evpn[0].id}/rttp-export"
  class_name = "rtctrlRttP"
  content = {
    type = "export"
  }
}

resource "nxos_rest" "rtctrlRttEntry-ipv4-ucast-ipv4-ucast-import-auto" {
  count = var.ipv4_unicast_rt_both_auto ? 1 : 0
  dn         = "${nxos_rest.rtctrlRttP-ipv4-ucast-ipv4-ucast-import[0].id}/ent-route-target:unknown:0:0"
  class_name = "rtctrlRttEntry"
  content = {
    rtt = "route-target:unknown:0:0"
  }
}

resource "nxos_rest" "rtctrlRttEntry-ipv4-ucast-ipv4-ucast-export-auto" {
  count = var.ipv4_unicast_rt_both_auto ? 1 : 0
  dn         = "${nxos_rest.rtctrlRttP-ipv4-ucast-ipv4-ucast-export[0].id}/ent-route-target:unknown:0:0"
  class_name = "rtctrlRttEntry"
  content = {
    rtt = "route-target:unknown:0:0"
  }
}

# RT auto

resource "nxos_rest" "rtctrlRttEntry-ipv4-ucast-l2vpn-evpn-import-auto" {
  count = var.ipv4_unicast_rt_both_auto_evpn ? 1 : 0
  dn         = "${nxos_rest.rtctrlRttP-ipv4-ucast-l2vpn-evpn-import[0].id}/ent-route-target:unknown:0:0"
  class_name = "rtctrlRttEntry"
  content = {
    rtt = "route-target:unknown:0:0"
  }
}

resource "nxos_rest" "rtctrlRttEntry-ipv4-ucast-l2vpn-evpn-export-auto" {
  count = var.ipv4_unicast_rt_both_auto_evpn ? 1 : 0
  dn         = "${nxos_rest.rtctrlRttP-ipv4-ucast-l2vpn-evpn-export[0].id}/ent-route-target:unknown:0:0"
  class_name = "rtctrlRttEntry"
  content = {
    rtt = "route-target:unknown:0:0"
  }
}

# address family ipv6 unicast

resource "nxos_rest" "rtctrlDomAf-ipv6-ucast" {
  count = var.ipv6_unicast ? 1 : 0
  dn         = "${nxos_rest.rtctrlDom.id}/af-ipv6-ucast"
  class_name = "rtctrlDomAf"
  content = {
    type = "ipv6-ucast"
  }
}

resource "nxos_rest" "rtctrlAfCtrl-ipv6-ucast-ipv6-ucast" {
  count = local.ipv6_import_ipv6 || local.ipv6_export_ipv6 ? 1 : 0
  dn         = "${nxos_rest.rtctrlDomAf-ipv6-ucast[0].id}/ctrl-ipv6-ucast"
  class_name = "rtctrlAfCtrl"
  content = {
    type = "ipv6-ucast"
  }
}

resource "nxos_rest" "rtctrlAfCtrl-ipv6-ucast-l2vpn-evpn" {
  count = local.ipv6_import_evpn || local.ipv6_export_evpn ? 1 : 0
  dn         = "${nxos_rest.rtctrlDomAf-ipv6-ucast[0].id}/ctrl-l2vpn-evpn"
  class_name = "rtctrlAfCtrl"
  content = {
    type = "l2vpn-evpn"
  }
}

resource "nxos_rest" "rtctrlRttP-ipv6-ucast-ipv6-ucast-import" {
  count = local.ipv6_import_ipv6 ? 1 : 0
  dn         = "${nxos_rest.rtctrlAfCtrl-ipv6-ucast-ipv6-ucast[0].id}/rttp-import"
  class_name = "rtctrlRttP"
  content = {
    type = "import"
  }
}

resource "nxos_rest" "rtctrlRttP-ipv6-ucast-ipv6-ucast-export" {
  count = local.ipv6_export_ipv6 ? 1 : 0
  dn         = "${nxos_rest.rtctrlAfCtrl-ipv6-ucast-ipv6-ucast[0].id}/rttp-export"
  class_name = "rtctrlRttP"
  content = {
    type = "export"
  }
}

resource "nxos_rest" "rtctrlRttP-ipv6-ucast-l2vpn-evpn-import" {
  count = local.ipv6_import_evpn ? 1 : 0
  dn         = "${nxos_rest.rtctrlAfCtrl-ipv6-ucast-l2vpn-evpn[0].id}/rttp-import"
  class_name = "rtctrlRttP"
  content = {
    type = "import"
  }
}

resource "nxos_rest" "rtctrlRttP-ipv6-ucast-l2vpn-evpn-export" {
  count = local.ipv6_export_evpn ? 1 : 0
  dn         = "${nxos_rest.rtctrlAfCtrl-ipv6-ucast-l2vpn-evpn[0].id}/rttp-export"
  class_name = "rtctrlRttP"
  content = {
    type = "export"
  }
}

resource "nxos_rest" "rtctrlRttEntry-ipv6-ucast-ipv6-ucast-import-auto" {
  count = var.ipv6_unicast_rt_both_auto ? 1 : 0
  dn         = "${nxos_rest.rtctrlRttP-ipv6-ucast-ipv6-ucast-import[0].id}/ent-route-target:unknown:0:0"
  class_name = "rtctrlRttEntry"
  content = {
    rtt = "route-target:unknown:0:0"
  }
}

resource "nxos_rest" "rtctrlRttEntry-ipv6-ucast-ipv6-ucast-export-auto" {
  count = var.ipv6_unicast_rt_both_auto ? 1 : 0
  dn         = "${nxos_rest.rtctrlRttP-ipv6-ucast-ipv6-ucast-export[0].id}/ent-route-target:unknown:0:0"
  class_name = "rtctrlRttEntry"
  content = {
    rtt = "route-target:unknown:0:0"
  }
}

# RT auto

resource "nxos_rest" "rtctrlRttEntry-ipv6-ucast-l2vpn-evpn-import-auto" {
  count = var.ipv6_unicast_rt_both_auto_evpn ? 1 : 0
  dn         = "${nxos_rest.rtctrlRttP-ipv6-ucast-l2vpn-evpn-import[0].id}/ent-route-target:unknown:0:0"
  class_name = "rtctrlRttEntry"
  content = {
    rtt = "route-target:unknown:0:0"
  }
}

resource "nxos_rest" "rtctrlRttEntry-ipv6-ucast-l2vpn-evpn-export-auto" {
  count = var.ipv6_unicast_rt_both_auto_evpn ? 1 : 0
  dn         = "${nxos_rest.rtctrlRttP-ipv6-ucast-l2vpn-evpn-export[0].id}/ent-route-target:unknown:0:0"
  class_name = "rtctrlRttEntry"
  content = {
    rtt = "route-target:unknown:0:0"
  }
}

# end of RT config section

resource "nxos_rest" "ipv4Dom" {
  dn         = "sys/ipv4/inst/dom-${var.name}"
  class_name = "ipv4Dom"
  content = {
    name = var.name
  }
}