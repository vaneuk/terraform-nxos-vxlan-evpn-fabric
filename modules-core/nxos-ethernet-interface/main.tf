resource "nxos_rest" "l1PhysIf" {
  dn         = "sys/intf/phys-[${var.id}]"
  class_name = "l1PhysIf"
  content = {
    id            = var.id
    descr         = var.description
    layer         = var.layer
    mode          = var.mode
    mtu           = var.mtu
    adminSt       = var.state
    speed         = var.speed
    linkDebounce = var.debounce
    # name          = "${var.id}-${var.description}-${var.speed}"
    # userCfgdFlags = "admin_mtu,admin_state"
  }
}

resource "nxos_rest" "nwRtVrfMbr" {
  count      = var.vrf != null ? 1 : 0
  dn         = "${nxos_rest.l1PhysIf.id}/rtvrfMbr"
  class_name = "nwRtVrfMbr"
  content = {
    tDn = "sys/inst-${var.vrf}"
  }
  depends_on = [
    nxos_rest.l1PhysIf
  ]
}

resource "nxos_rest" "ipv4If" {
  count      = var.ip_address != null ? 1 : 0
  dn         = "sys/ipv4/inst/dom-[${var.vrf}]/if-[${var.id}]"
  class_name = "ipv4If"
  content = {
    id = var.id
  }
  depends_on = [
    nxos_rest.nwRtVrfMbr
  ]
}

resource "nxos_rest" "ipv4Addr" {
  count      = var.ip_address != null ? 1 : 0
  dn         = "${nxos_rest.ipv4If[0].id}/addr-[${var.ip_address}]"
  class_name = "ipv4Addr"
  content = {
    addr = var.ip_address
  }
  depends_on = [nxos_rest.ipv4If]
}
