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
| [nxos_rest.ipv4Dom](https://registry.terraform.io/providers/netascode/nxos/latest/docs/resources/rest) | resource |
| [nxos_rest.l3Inst](https://registry.terraform.io/providers/netascode/nxos/latest/docs/resources/rest) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name"></a> [name](#input\_name) | VRF Name | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dn"></a> [dn](#output\_dn) | Distinguished name of `l3Inst` object. |
| <a name="output_l3Inst"></a> [l3Inst](#output\_l3Inst) | VRF Name |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->