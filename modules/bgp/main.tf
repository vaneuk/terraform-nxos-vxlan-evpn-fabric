
module "nxos_bgp" {
  source     = "../../modules-core/nxos-bgp"
  asn       = var.model.bgp.asn
  enhanced_error = var.model.bgp.enhanced_error
  template_peers = var.model.bgp.template_peers
  # log_neighbor_changes = var.model.bgp.log_neighbor_changes
  # vrf                      = lookup(each.value, "vrf", "default")
  vrfs                      = var.model.bgp.vrfs
  # router_id                = lookup(each.value, "router_id", null)
  # adjancency_logging_level = lookup(each.value, "adjancency_logging_level", "none")
}
