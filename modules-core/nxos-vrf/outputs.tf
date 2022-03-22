output "dn" {
  value       = nxos_rest.l3Inst.id
  description = "Distinguished name of `l3Inst` object."
}

output "l3Inst" {
  value       = nxos_rest.l3Inst.content.name
  description = "VRF Name"
}