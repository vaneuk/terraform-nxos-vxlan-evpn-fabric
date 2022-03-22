variable "id" {
  description = "Interface ID. Must match first field in the output of `show intf brief`. Example: `eth1/1`."
  type        = string
}

variable "description" {
  description = "Interface description"
  type        = string
  default     = ""
}

variable "state" {
  description = "Interface State"
  type        = string
  default     = "up"
}

variable "speed" {
  description = "Administrative port speed"
  type        = string
  default     = "auto"
}

variable "mtu" {
  description = "Administrative port MTU"
  type        = number
  default     = 1500
}

variable "debounce" {
  description = "Link debounce timer"
  type        = number
  default     = 100
}

variable "mode" {
  description = "Interface mode. Choices: `access`, `trunk`, `fex-fabric`, `dot1q-tunnel`, `promiscuous`, `host`, `trunk_secondary`, `trunk_promiscuous`, `vntag`."
  type        = string
  default     = "access"

}

variable "layer" {
  description = "Interface Operational Layer"
  type        = string
  default     = "Layer2"
}

variable "vrf" {
  description = "Interface VRF"
  type        = string
  default     = "default"

}

variable "ip_address" {
  description = "Interface IPv4 Address"
  type        = string
  default     = null
}