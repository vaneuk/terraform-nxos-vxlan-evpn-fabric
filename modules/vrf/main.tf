locals {
  vrfs_set = toset([
    for service_name, service in lookup(var.model, "l2vni", {}) : service.vrf if length(setintersection(toset(service.apply_to), toset(var.groups))) > 0
    ])
  vrfs = {
    for vrf_name in local.vrfs_set: vrf_name => var.model.l3vni[vrf_name]
  }
}

module "nxos_vrf" {
  source   = "../../modules-core/nxos-vrf"
  for_each = local.vrfs
  name     = each.key
  vni      = each.value.vni
  rd = each.value.rd
  ipv4_unicast = true
  ipv4_unicast_rt_both_auto = true
  ipv4_unicast_rt_both_auto_evpn = true
  ipv6_unicast = true
  ipv6_unicast_rt_both_auto = true
  ipv6_unicast_rt_both_auto_evpn = true
}
