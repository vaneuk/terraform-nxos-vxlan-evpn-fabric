# Cisco Nexus 9000 VXLAN EVPN Fabric Terraform example

This example demonstrates how the [NX-OS Terraform Provider](https://registry.terraform.io/providers/netascode/nxos/latest/docs) can be used to build a Cisco Nexus 9000 EVPN Fabric.

It configures the following:
- Hostname
- Features
- VLANs
- VLAN interfaces
- Loopback interfaces
- underlay interfaces
- trunk downlink interfaces (for Leaf)
- underlay OSPF
- BGP
- Fabric Forwading MAC address
- NVE interface
- EVPN section
- VRFs

Not supported:
- VPC
- STP
- PIM
- Port-channels

This repository uses general-purpose [Terraform NX-OS Configuration Module](https://registry.terraform.io/modules/netascode/config/nxos/latest), which introduces another level of abstraction for the end user.

## Configuration

The configuration is derived from the following directories:

- `vars/static` - staticaly defined variables in YAML format.
- `vars/dynamic` - dynamically defined variables that are generated during `python generare.py` execution.
- `data/overlay_services` - YAML configuration files for overlay services (L2VNI and L3VNI).
- `data/groups` - Jinja2 templates that are used to generate YAML configuration files. These templates use variables defined in the directories mentioned above. Configurations are merged based on device membership in groups.

Resulting configuration in YAML format is saved to `configs` directory. Configuration is in format supported by [Terraform NX-OS Configuration Module](https://registry.terraform.io/modules/netascode/config/nxos/latest).

## Usage

### Inventory
To point this to your own Nexus fabric, update the `inventory.yaml` file accordingly.

```yaml
---
- name: site-1-spine-1
  url: https://10.0.24.202
  site: 1
  id: 1
  role: spine
  groups: []
```

### Authentication
Credentials can either be provided via environment variables:

```shell
export NXOS_USERNAME=admin
export NXOS_PASSWORD=Cisco123
```

Or by updating the provider configuration in `main.tf`:

```terraform
provider "nxos" {
  username = admin
  password = Cisco123
  devices  = local.devices
}
```

### Configuration generation and apply

Install python 3 requirements:
```shell
pip install -r requirements.txt
```

Generate configuration files:
```shell
python generate.py
```

Run Terraform:
```shell
terraform init
terraform plan
terraform apply
```