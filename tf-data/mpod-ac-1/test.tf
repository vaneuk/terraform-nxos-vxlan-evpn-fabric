variable "vrfs" {
  description = "OSPF VRF Name"
  type = map(object({
    router_id                = optional(string)
    adjancency_logging_level = optional(string)
    areas = optional(list(object({
      id                  = string
      authentication_type = optional(string)
    })))
    interfaces = optional(map(object({
      area                  = optional(string)
      advertise_secondaries = optional(string)
      network_type          = optional(string)
      cost                  = optional(string)
      md5key                = optional(string)
    })))
  }))
  default = {
    foo = {
      router_id = "a"
      interfaces = {
        "eth1/41" = {
          advertise_secondaries = "1.2.3"
        }
        "eth1/45" = {
          area = "0"
        }
      }
    }
    bar = {
      router_id = "a"
      interfaces = {
        "eth1/42" = {
          advertise_secondaries = "1.2.3"
        }
      }
    }
  }
}

# output "test" {
#   value = var.vrfs
# }
# merge(vrf.interfaces, { "vrf" : vrf_name })
locals {
  interfaces_list = [
    for vrf_name, vrf in var.vrfs : {
      for interface_name, interface in vrf.interfaces : interface_name => merge(interface, { "vrf" : vrf_name })
    }
  ]
  interfaces_map = merge(local.interfaces_list...)
}

# output "interfaces_list" {
#   value = local.interfaces_list
# }

# output "interfaces_map" {
#   value = local.interfaces_map
# }
