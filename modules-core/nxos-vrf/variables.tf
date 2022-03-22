variable "name" {
  description = "VRF Name"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9_.-]{0,64}$", var.name))
    error_message = "Allowed characters: `a`-`z`, `A`-`Z`, `0`-`9`, `_`, `.`, `-`. Maximum characters: 64."
  }
}

variable "vni" {
  description = "VRF VNI"
  type        = number
  default     = null
}

variable "rd" {
  description = "VRF route distinguisher"
  type        = string
  default     = null
}

# variable "ipv4_unicast" {
#   description = "VRF route distinguisher"
#   type        = bool
#   default     = false
# }

# variable "address_family" {
#   description = "VRF route distinguisher"
#   type = map(object({
#     rt_both_auto      = optional(bool)
#     rt_both_auto_evpn = optional(bool)
#     rt_import         = optional(list(string))
#     rt_export         = optional(list(string))
#   }))
#   default = {}
# }

variable "ipv4_unicast" {
  type    = bool
  default = false
}

variable "ipv4_unicast_rt_both_auto" {
  type    = bool
  default = false
}

variable "ipv4_unicast_rt_both_auto_evpn" {
  type    = bool
  default = false
}

variable "ipv4_unicast_rt_import" {
  type    = list(string)
  default = []
}

variable "ipv4_unicast_rt_export" {
  type    = list(string)
  default = []
}

variable "ipv4_unicast_rt_import_evpn" {
  type    = list(string)
  default = []
}

variable "ipv4_unicast_rt_export_evpn" {
  type    = list(string)
  default = []
}

variable "ipv6_unicast" {
  type    = bool
  default = false
}

variable "ipv6_unicast_rt_both_auto" {
  type    = bool
  default = false
}

variable "ipv6_unicast_rt_both_auto_evpn" {
  type    = bool
  default = false
}

variable "ipv6_unicast_rt_import" {
  type    = list(string)
  default = []
}

variable "ipv6_unicast_rt_export" {
  type    = list(string)
  default = []
}

variable "ipv6_unicast_rt_import_evpn" {
  type    = list(string)
  default = []
}

variable "ipv6_unicast_rt_export_evpn" {
  type    = list(string)
  default = []
}
