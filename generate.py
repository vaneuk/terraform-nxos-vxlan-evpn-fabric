import ipaddress
import logging
from typing import Optional

import yaml
from deepmerge import always_merger
from jinja2 import Environment, FileSystemLoader, exceptions
from pydantic import BaseModel

from helpers import convert_dicts_to_lists, dict_replace_none, join_consecutive_vlans


FILE_LOADER = FileSystemLoader("data/groups")
ENV = Environment(loader=FILE_LOADER)


class NoAliasDumper(yaml.SafeDumper):
    def ignore_aliases(self, data):
        return True


class ModelConstructor(BaseModel):
    model_data: dict
    services_data: dict
    groups: list[str]
    model: Optional[dict]

    # @classmethod
    def construct_model(self):
        self.model = convert_dicts_to_lists(self.model_data)
        self.convert_features()
        # self.add_model_info()
        return self.model

    def convert_features(self):
        features = [k for k, v in self.model["features"].items() if v]
        self.model["features"] = features


def apply_to_device(apply_to, groups):
    apply_to_groups = apply_to.keys()
    intersection = list(set(apply_to_groups) & set(groups))
    # return True if there is intersection
    return len(intersection) > 0


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

    def load_services_data(self):
        for file in ["l2vni", "l3vni"]:
            path = f"data/overlay_services/{file}.yaml"
            with open(path, "r") as f:
                tmp = yaml.safe_load(f)
                if tmp:
                    self.services_data = always_merger.merge(self.services_data, tmp)

    def add_dynamic_vars(self, inventory):
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

        # SERVICES
        if self.role == "leaf":
            self.dynamic_vars["downlinks"] = {}
            self.dynamic_vars["services"] = {}
            self.dynamic_vars["services"]["l2vni"] = []
            self.dynamic_vars["services"]["l3vni"] = []

            # List of L2VNIs applied to device
            for service_name, service in self.services_data["l2vni"].items():
                if apply_to_device(service["apply_to"], self.groups):
                    self.dynamic_vars["services"]["l2vni"].append(service_name)

            # List of L3VNIs applied to device (== VRFs)
            for l2vni in self.dynamic_vars["services"]["l2vni"]:
                if self.services_data["l2vni"][l2vni]["vrf"] not in self.dynamic_vars["services"]["l3vni"]:
                    self.dynamic_vars["services"]["l3vni"].append(self.services_data["l2vni"][l2vni]["vrf"])

            # Downlinks
            for l2vni in self.dynamic_vars["services"]["l2vni"]:
                if self.services_data["l2vni"][l2vni]["apply_to"]:
                    if self.services_data["l2vni"][l2vni]["apply_to"][self.name]:
                        for interface in self.services_data["l2vni"][l2vni]["apply_to"][self.name]:
                            # TODO change this
                            if "eth" in interface:
                                interface_type = "eth"
                                interface_id = interface.replace("eth", "")
                            if interface_type not in self.dynamic_vars["downlinks"]:
                                self.dynamic_vars["downlinks"][interface_type] = {}
                            if interface_id not in self.dynamic_vars["downlinks"][interface_type]:
                                self.dynamic_vars["downlinks"][interface_type][interface_id] = {
                                    "vlan_list": [],
                                    "vlans": "",
                                }
                            self.dynamic_vars["downlinks"][interface_type][interface_id]["vlan_list"].append(
                                self.services_data["l2vni"][l2vni]["vlan"]
                            )

            # summarize Vlans
            for interfaces in self.dynamic_vars["downlinks"].values():
                for interface in interfaces.values():
                    interface["vlans"] = join_consecutive_vlans(interface["vlan_list"])

        self.vars = always_merger.merge(self.vars, self.dynamic_vars)
        path = f"vars/dynamic/{self.name}.yaml"
        with open(path, "w") as f:
            yaml.dump(self.dynamic_vars, f, Dumper=NoAliasDumper)

    def load_groups_data(self):
        for group in self.groups:
            path = f"data/groups/{group}.yaml"
            try:
                with open(path, "r") as f:
                    template = ENV.get_template(f"{group}.yaml")
                    template_string = template.render(**self.vars, **self.services_data)
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

    def prepare_model(self):
        # convert Dict to Lists
        model_constructor = ModelConstructor(
            model_data=self.model_data,
            services_data=self.services_data,
            groups=self.groups,
        )
        self.model = model_constructor.construct_model()

    def write_model(self):
        path = f"configs/{self.name}.yaml"
        # replace interfaces_vlan: null to interfaces_vlan: []
        # TODO move this logic to Jinja?
        model_formatted = dict_replace_none(self.model)
        with open(path, "w") as f:
            yaml.dump(model_formatted, f, Dumper=NoAliasDumper)


if __name__ == "__main__":
    hosts = []
    with open("inventory.yaml", "r") as f:
        inventory = yaml.safe_load(f)
    for host in inventory:
        hosts.append(Host.parse_obj(host))

    for host in hosts:
        host.update_groups()
        host.load_services_data()
        host.load_vars()
        host.add_dynamic_vars(inventory)
        host.load_groups_data()
        host.prepare_model()
        host.write_model()
