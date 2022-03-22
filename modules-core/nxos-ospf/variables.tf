variable "name" {
  description = "OSPF Instance Name"
  type        = string
}
    # name = string
        # id                    = string
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
      cost                  = optional(number)
      md5key                = optional(string)
    })))
  }))
  default = {}

  # validation {
  #   condition     = can(regex("^[a-zA-Z0-9_.-]{0,64}$", var.vrf))
  #   error_message = "Allowed characters: `a`-`z`, `A`-`Z`, `0`-`9`, `_`, `.`, `-`. Maximum characters: 64."
  # }
}

# variable "apply_to" {
#   description = "foo"
#   type        = list(string)
# }

# variable "router_id" {
#   description = "OSPF Router ID"
#   type        = string
#   default     = "0.0.0.0"
# }

# variable "adjancency_logging_level" {
#   description = "Adjacency change logging level"
#   type        = string
#   default     = "Adjacency change logging level"
# }

# variable "areas" {
#   description = "List of Areas"
#   type = list(object({
#     id                  = string
#     authentication_type = optional(string)
#   }))
#   default = []

# }

# variable "interfaces" {
#   description = "List of OSPF-enabled interfaces"
#   type = list(object({
#     id                    = string
#     area                  = optional(string)
#     advertise_secondaries = optional(string)
#     network_type          = optional(string)
#     cost                  = optional(number)
#     md5key                = optional(string)
#   }))
#   default = []

# }