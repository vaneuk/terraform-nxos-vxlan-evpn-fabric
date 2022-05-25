import logging
from typing import Optional

import yaml
from deepmerge import always_merger
from jinja2 import Environment, FileSystemLoader, exceptions
from pydantic import BaseModel
import ipaddress

from fm import converter


class NoAliasDumper(yaml.SafeDumper):
    def ignore_aliases(self, data):
        return True


FILE_LOADER = FileSystemLoader("data/groups")
ENV = Environment(loader=FILE_LOADER)


def convert_features(features):
    result = []
    for k, v in features.items():
        if v:
            result.append(k)

    return result


def add_hostname(model, hostname):
    model["hostname"] = hostname

def convert_interfaces(model, templates):
    for interface in model["interfaces_ethernet"]:
        if "template" in interface:
            interface.update(templates["interface_templates"][interface["template"]])
            del interface["template"]


def apply_to_device(apply_to, groups):
    intersection = list(set(apply_to) & set(groups))
    if len(intersection) == 0:
        return False
    else:
        return True


def add_vrf_info(model, services, templates, groups):
    # TODO REFACTOR
    device_vlans = []
    device_vrfs = []
    device_interfaces_vlan = []
    for service_name, service in services["l2vni"].items():
        if apply_to_device(service["apply_to"], groups):
            vlan_entry = {"id": service["vlan"], "name": service_name}
            device_vlans.append(vlan_entry)
    model["vlans"] = device_vlans

    vrf_list = []
    for vlan in device_vlans:
        if services["l2vni"][vlan["name"]]["vrf"] not in vrf_list:
            vrf_list.append(services["l2vni"][vlan["name"]]["vrf"])

    for vrf in vrf_list:
        vrf_entry = (
            services["l3vni"][vrf] | {"name": vrf} | templates["vrf_templates"]["auto"]
        )
        device_vrfs.append(vrf_entry)

    model["vrfs"] = device_vrfs

    for vrf in device_vrfs:
        l3vni_vlan = {
            "id": services["l3vni"][vrf["name"]]["vlan"],
            "description": vrf.get("description", ""),
            "mtu": vrf.get("mtu", 9216),
            "ip_forward": True,
            "vrf": vrf["name"],
        }
        device_interfaces_vlan.append(l3vni_vlan)

    for vlan in device_vlans:
        l2vni_vlan = {
            "id": vlan["id"],
            "description": vlan["name"],
            "mtu": services["l2vni"][vlan["name"]]["mtu"],
            "vrf": services["l2vni"][vlan["name"]]["vrf"],
        }
        device_interfaces_vlan.append(l2vni_vlan)

    model["interfaces_vlan"] = device_interfaces_vlan


class Host(BaseModel):
    name: str
    url: str
    site: int
    id: int
    role: str
    groups: list[str]
    vars = {}
    dynamic_vars = {}
    model_data = {}
    services_data = {}
    templates_data = {}
    model: Optional[dict]

    def update_groups(self):
        self.groups.insert(0, "all")
        self.groups.append(f"site-{self.site}")
        self.groups.append(self.role)
        self.groups.append(self.name)

    def load_vars(self):
        for group in self.groups:
            path = f"vars/static/{group}.yaml"
            try:
                with open(path, "r") as f:
                    self.vars.update(yaml.safe_load(f))
            except FileNotFoundError:
                print(f"Failed to load vars file {path} for host {self.name}")

    def generate_dynamic_vars(self):
        first2octets = self.vars["underlay_ip_pool"].split(".")[:2]
        if self.role == "leaf":
            for h in inventory if h["role"] == "spine":
                print(h)
            

    def load_groups_data(self):
        for group in self.groups:
            path = f"data/groups/{group}.yaml"
            try:
                with open(path, "r") as f:
                    template = ENV.get_template(f"{group}.yaml")
                    tmp = yaml.safe_load(template.render(**self.vars))
                    if tmp:
                        self.model_data = always_merger.merge(self.model_data, tmp)
            except FileNotFoundError:
                print(f"Failed to load template file {path} for host {self.name}")
            except exceptions.UndefinedError as e:
                print(
                    f"Template variable {e}. Template file {path} for host {self.name}"
                )

    def load_services_data(self):
        for file in ["l2vni", "l3vni"]:
            path = f"data/overlay_services/{file}.yaml"
            with open(path, "r") as f:
                tmp = yaml.safe_load(f)
                if tmp:
                    self.services_data = always_merger.merge(self.services_data, tmp)

    def load_templates_data(self):
        path = f"data/templates/templates.yaml"
        with open(path, "r") as f:
            self.templates_data = yaml.safe_load(f)

    def prepare_model(self):
        # convert Dict to Lists
        self.model = converter(self.model_data)
        self.model["features"] = convert_features(self.model["features"])
        convert_interfaces(self.model, self.templates_data)
        add_vrf_info(self.model, self.services_data, self.templates_data, self.groups)
        add_hostname(self.model, self.name)

    def write_model(self):
        path = f"configs/{self.name}.yaml"
        with open(path, "w") as f:
            yaml.dump(self.model, f, Dumper=NoAliasDumper)


if __name__ == "__main__":
    hosts = []
    with open("inventory.yaml", "r") as f:
        inventory = yaml.safe_load(f)
    for host in inventory:
        hosts.append(Host.parse_obj(host))

    for host in hosts:
        host.update_groups()
        host.load_vars()
        host.generate_dynamic_vars()
        host.load_groups_data()
        host.load_services_data()
        host.load_templates_data()
        host.prepare_model()
        host.write_model()
