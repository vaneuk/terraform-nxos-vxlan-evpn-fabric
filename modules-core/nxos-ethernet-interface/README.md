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
| [nxos_rest.ipv4Addr](https://registry.terraform.io/providers/netascode/nxos/latest/docs/resources/rest) | resource |
| [nxos_rest.ipv4If](https://registry.terraform.io/providers/netascode/nxos/latest/docs/resources/rest) | resource |
| [nxos_rest.l1PhysIf](https://registry.terraform.io/providers/netascode/nxos/latest/docs/resources/rest) | resource |
| [nxos_rest.nwRtVrfMbr](https://registry.terraform.io/providers/netascode/nxos/latest/docs/resources/rest) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_description"></a> [description](#input\_description) | Interface description | `string` | `""` | no |
| <a name="input_id"></a> [id](#input\_id) | Interface ID. Must match first field in the output of `show intf brief`. Example: `eth1/1`. | `string` | n/a | yes |
| <a name="input_ip_address"></a> [ip\_address](#input\_ip\_address) | Interface IPv4 Address | `string` | `null` | no |
| <a name="input_layer"></a> [layer](#input\_layer) | Interface Operational Layer | `string` | `"Layer2"` | no |
| <a name="input_mode"></a> [mode](#input\_mode) | Interface mode. Choices: `access`, `trunk`, `fex-fabric`, `dot1q-tunnel`, `promiscuous`, `host`, `trunk_secondary`, `trunk_promiscuous`, `vntag`. | `string` | `"access"` | no |
| <a name="input_mtu"></a> [mtu](#input\_mtu) | Administrative port MTU | `number` | `1500` | no |
| <a name="input_speed"></a> [speed](#input\_speed) | Administrative port speed | `string` | `"auto"` | no |
| <a name="input_state"></a> [state](#input\_state) | Interface State | `string` | `"up"` | no |
| <a name="input_vrf"></a> [vrf](#input\_vrf) | Interface VRF | `string` | `"default"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dn"></a> [dn](#output\_dn) | Distinguished name of `l1PhysIf` object. |
| <a name="output_id"></a> [id](#output\_id) | Interface ID. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->