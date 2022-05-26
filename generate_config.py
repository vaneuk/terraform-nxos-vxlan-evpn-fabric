import ipaddress
import logging
from typing import Optional

import yaml
from deepmerge import always_merger
from jinja2 import Environment, FileSystemLoader, exceptions
from pydantic import BaseModel

from helpers import convert_dicts_to_lists


FILE_LOADER = FileSystemLoader("data/groups")
ENV = Environment(loader=FILE_LOADER)


class NoAliasDumper(yaml.SafeDumper):
    def ignore_aliases(self, data):
        return True


class ModelConstructor(BaseModel):
    model_data: dict
    services_data: dict
    templates_data: dict
    groups: list[str]
    model: Optional[dict]

    # @classmethod
    def construct_model(self):
        self.model = convert_dicts_to_lists(self.model_data)
        self.convert_features()
        self.add_model_info()
        return self.model

    def __apply_to_device(apply_to, groups):
        intersection = list(set(apply_to) & set(groups))
        # return True if there is intersection
        return len(intersection) > 0

    def convert_features(self):
        features = [k for k, v in self.model["features"].items() if v]
        self.model["features"] = features

    def add_model_info(self):
        # TODO REFACTOR
        device_vlans = []
        device_vrfs = []
        device_interfaces_vlan = []
        for service_name, service in self.services_data["l2vni"].items():
            if self.__apply_to_device(service["apply_to"], self.groups):
                vlan_entry = {"id": service["vlan"], "name": service_name}
                device_vlans.append(vlan_entry)
        self.model["vlans"] = device_vlans

        vrf_list = []
        for vlan in device_vlans:
            if self.services_data["l2vni"][vlan["name"]]["vrf"] not in vrf_list:
                vrf_list.append(self.services_data["l2vni"][vlan["name"]]["vrf"])

        for vrf in vrf_list:
            vrf_entry = {
                "name": vrf,
                "description": self.services_data["l3vni"][vrf]["description"],
                "vni": self.services_data["l3vni"][vrf]["vni"],
            }
            vrf_entry.update(self.templates_data["vrf_templates"]["auto"])
            device_vrfs.append(vrf_entry)

        self.model["vrfs"].extend(device_vrfs)

        for vrf in device_vrfs:
            l3vni_vlan = {
                "id": self.services_data["l3vni"][vrf["name"]]["vlan"],
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
                "mtu": self.services_data["l2vni"][vlan["name"]]["mtu"],
                "vrf": self.services_data["l2vni"][vlan["name"]]["vrf"],
            }
            device_interfaces_vlan.append(l2vni_vlan)

        self.model["interfaces_vlan"] = device_interfaces_vlan


# def load_yaml(path, data):
#     with open(path, "r") as f:
#         tmp = yaml.safe_load(f)
#         if tmp:
#             data.update(tmp)


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
                    tmp = yaml.safe_load(f)
                    if tmp:
                        self.vars = always_merger.merge(self.vars, tmp)
            except FileNotFoundError:
                print(f"Failed to load vars file {path} for host {self.name}")

    def generate_dynamic_vars(self, inventory):
        # TODO change this
        self.dynamic_vars["ip"] = {}
        self.dynamic_vars["underlay_interfaces"] = []
        loopback_network = ipaddress.ip_network(self.vars["ip"]["pool"][f"loopback_{self.role}"])
        underlay_network = ipaddress.ip_network(self.vars["ip"]["pool"][f"underlay"])
        self.dynamic_vars["ip"]["lo0"] = str(loopback_network[self.id])
        module_number, interface_number = [int(i) for i in self.vars["first_underlay_interface"].split("/")]
        if self.role == "leaf":
            self.dynamic_vars["bgp"] = {}
            self.dynamic_vars["bgp"]["spine_peers"] = []
            spine_loopback_network = ipaddress.ip_network(self.vars["ip"]["pool"][f"loopback_spine"])
            for host in inventory:
                if host["role"] == "spine":
                    # Underlay IPs
                    ip_number = 256 * host["id"] + (self.id - 1) * 2
                    interface = f"{module_number}/{interface_number}"
                    self.dynamic_vars["ip"][interface] = str(underlay_network[ip_number])
                    self.dynamic_vars["underlay_interfaces"].append(interface)
                    interface_number += 1

                    # BGP Peers
                    self.dynamic_vars["bgp"]["spine_peers"].append(
                        {"ip": str(spine_loopback_network[host["id"]]), "name": host["name"]}
                    )

        elif self.role == "spine":
            for host in inventory:
                if host["role"] == "leaf":
                    ip_number = 256 * self.id + (host["id"] - 1) * 2 + 1
                    interface = f"{module_number}/{interface_number}"
                    self.dynamic_vars["ip"][interface] = str(underlay_network[ip_number])
                    self.dynamic_vars["underlay_interfaces"].append(interface)
                    interface_number += 1

        self.dynamic_vars["hostname"] = self.name
        self.vars = always_merger.merge(self.vars, self.dynamic_vars)
        path = f"vars/generated/{self.name}.yaml"
        with open(path, "w") as f:
            yaml.dump(self.dynamic_vars, f, Dumper=NoAliasDumper)

    def load_groups_data(self):
        for group in self.groups:
            path = f"data/groups/{group}.yaml"
            try:
                with open(path, "r") as f:
                    template = ENV.get_template(f"{group}.yaml")
                    template_string = template.render(**self.vars)
                    tmp = yaml.safe_load(template_string)
                    if tmp:
                        self.model_data = always_merger.merge(self.model_data, tmp)
            except FileNotFoundError:
                print(f"Template file {path} for host {self.name}. Not Found.")
            except exceptions.UndefinedError as e:
                print(f"Template file {path} for host {self.name}. Template variable {e}.")
                quit()
            except yaml.parser.ParserError as e:
                print(f"Template file {path} for host {self.name}. YAML parser error: {e}")
                print(template_string)
                quit()

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
        model_constructor = ModelConstructor(
            model_data=self.model_data,
            services_data=self.services_data,
            templates_data=self.templates_data,
            groups=self.groups,
        )
        self.model = model_constructor.construct_model()

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
        host.generate_dynamic_vars(inventory)
        host.load_groups_data()
        host.load_services_data()
        host.load_templates_data()
        host.prepare_model()
        host.write_model()
