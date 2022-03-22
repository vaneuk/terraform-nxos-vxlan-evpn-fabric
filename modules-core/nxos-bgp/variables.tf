variable "asn" {
  description = "BGP AS Number"
  type        = number
}

variable "enhanced_error" {
  description = "BGP Enhanced error handling"
  type        = bool
  default     = true
}

variable "vrfs" {
  description = "BGP VRF"
  type = map(object({
    router_id            = optional(string)
    log_neighbor_changes = optional(bool)
    gr_stalepath_time = optional(number)
    gr_restart_time = optional(number)
    neighbors = optional(map(object({
      inherit_peer = optional(string)
      description  = optional(string)
    })))
  }))
  default = {}
}

variable "template_peers" {
  description = "BGP template peers"
  type = map(object({
    asn              = optional(number)
    source_interface = optional(string)
    address_family = optional(map(object({
      send_community_standard = optional(bool)
      send_community_extended = optional(bool)
    })))
  }))
  default = {}
}

#   # validation {
#   #   condition     = can(regex("^[a-zA-Z0-9_.-]{0,64}$", var.vrf))
#   #   error_message = "Allowed characters: `a`-`z`, `A`-`Z`, `0`-`9`, `_`, `.`, `-`. Maximum characters: 64."
#   # }
# }

# # variable "apply_to" {
# #   description = "foo"
# #   type        = list(string)
# # }

# # variable "router_id" {
# #   description = "OSPF Router ID"
# #   type        = string
# #   default     = "0.0.0.0"
# # }

# # variable "adjancency_logging_level" {
# #   description = "Adjacency change logging level"
# #   type        = string
# #   default     = "Adjacency change logging level"
# # }

# # variable "areas" {
# #   description = "List of Areas"
# #   type = list(object({
# #     id                  = string
# #     authentication_type = optional(string)
# #   }))
# #   default = []

# # }

# # variable "interfaces" {
# #   description = "List of OSPF-enabled interfaces"
# #   type = list(object({
# #     id                    = string
# #     area                  = optional(string)
# #     advertise_secondaries = optional(string)
# #     network_type          = optional(string)
# #     cost                  = optional(number)
# #     md5key                = optional(string)
# #   }))
# #   default = []

# # }