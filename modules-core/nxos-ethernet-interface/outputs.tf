output "dn" {
  value       = nxos_rest.l1PhysIf.id
  description = "Distinguished name of `l1PhysIf` object."
}

output "id" {
  value       = nxos_rest.l1PhysIf.content.id
  description = "Interface ID."
}