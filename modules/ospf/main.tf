locals {
  ospfs = {for k, v in lookup(var.model, "ospf", {}) : k => v }
  # ospfs = {for k, v in lookup(var.model, "ospf", {}) : k => v if contains(v.apply_to, var.hostname)}
}

module "nxos_ospf" {
  source     = "../../modules-core/nxos-ospf"
  for_each   = local.ospfs
  name       = each.key
  vrfs                      = each.value.vrfs
}
