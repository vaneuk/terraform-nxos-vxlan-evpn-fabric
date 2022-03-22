# Overview

# Usage

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_nxos"></a> [nxos](#requirement\_nxos) | >= 0.1.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_nxos"></a> [nxos](#provider\_nxos) | >= 0.1.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [nxos_rest.ospfArea](https://registry.terraform.io/providers/netascode/nxos/latest/docs/resources/rest) | resource |
| [nxos_rest.ospfAuthNewP](https://registry.terraform.io/providers/netascode/nxos/latest/docs/resources/rest) | resource |
| [nxos_rest.ospfDom](https://registry.terraform.io/providers/netascode/nxos/latest/docs/resources/rest) | resource |
| [nxos_rest.ospfEntity](https://registry.terraform.io/providers/netascode/nxos/latest/docs/resources/rest) | resource |
| [nxos_rest.ospfIf](https://registry.terraform.io/providers/netascode/nxos/latest/docs/resources/rest) | resource |
| [nxos_rest.ospfInst](https://registry.terraform.io/providers/netascode/nxos/latest/docs/resources/rest) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_adjancency_logging_level"></a> [adjancency\_logging\_level](#input\_adjancency\_logging\_level) | Adjacency change logging level | `string` | `"Adjacency change logging level"` | no |
| <a name="input_areas"></a> [areas](#input\_areas) | List of Areas | <pre>list(object({<br>    id                  = string<br>    authentication_type = optional(string)<br>  }))</pre> | `[]` | no |
| <a name="input_interfaces"></a> [interfaces](#input\_interfaces) | List of OSPF-enabled interfaces | <pre>list(object({<br>    id                    = string<br>    area                  = optional(string)<br>    advertise_secondaries = optional(string)<br>    network_type          = optional(string)<br>    cost                  = optional(number)<br>    md5key                = optional(string)<br>  }))</pre> | `[]` | no |
| <a name="input_name"></a> [name](#input\_name) | OSPF Instance Name | `string` | n/a | yes |
| <a name="input_router_id"></a> [router\_id](#input\_router\_id) | OSPF Router ID | `string` | `"0.0.0.0"` | no |
| <a name="input_vrf"></a> [vrf](#input\_vrf) | OSPF VRF Name | `string` | `"default"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dn"></a> [dn](#output\_dn) | Distinguished name of `ospfDom` object. |
| <a name="output_name"></a> [name](#output\_name) | OSPF Instance Name |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->