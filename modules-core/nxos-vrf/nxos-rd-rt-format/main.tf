/*
vrf context foo
  rd 65535:1      --> "rd": "rd:as2-nn2:65535:1",

vrf context foo
  rd rd 65536:1   --> "rd": "rd:as4-nn2:65536:1",

vrf context foo
  rd 1.1.1.1:1    --> "rd": "rd:ipv4-nn2:1.1.1.1:1",

vrf context foo
  rd auto         --> "rd": "rd:unknown:0:0",

vrf context foo
  no rd           --> "rd": "unknown:unknown:0:0",
*/

locals {
  # format_map = {
  #   "format_none": "unknown:0:0"
  #   "format_auto": "unknown:0:0"
  #   "format_ipv4": try("ipv4-nn2:${var.value}", "__not_used")
  #   "format_as2": try("as2-nn2:${var.value}", "__not_used")
  #   "format_as4": try("as4-nn2:${var.value}", "__not_used")
  # }

  format_none = var.value == null ? true : false
  format_auto = var.value == "auto" ? true : false
  format_ipv4 = can(regex("\\.", var.value)) ? true : false
  format_as2  = !can(regex("\\.", var.value)) && can(regex(":", var.value)) ? (tonumber(split(":", var.value)[0]) <= 65535 ? true : false) : false
  format_as4  = !can(regex("\\.", var.value)) && can(regex(":", var.value)) ? (tonumber(split(":", var.value)[0]) >= 65536 ? true : false) : false

  result_rd = local.format_none ? "unknown:unknown:0:0" : (
    local.format_auto ? "rd:unknown:0:0" : (
      local.format_ipv4 ? "rd:ipv4-nn2:${var.value}" : (
        local.format_as2 ? "rd:as2-nn2:${var.value}" : (
          local.format_as4 ? "rd:as4-nn2:${var.value}" : "unexpected_rd_format"
  ))))
  result_rt = local.format_none ? "unknown:0:0" : (
    local.format_auto ? "unknown:0:0" : (
      local.format_ipv4 ? "ipv4-nn2:${var.value}" : (
        local.format_as2 ? "as2-nn2:${var.value}" : (
          local.format_as4 ? "as4-nn2:${var.value}" : "unexpected_rt_format"
  ))))
  result = var.rd ? local.result_rd : local.result_rt
}