"""
Helper script to convert Dicts to List.
Example.
Input:
{
  "bgp": {
    "asn": 65535,
    "enhanced_error": false,
    "template_peers": {
      "SPINE-PEERS": {
        "asn": 65536,
        "source_interface": "lo0",
        "address_families": {
          "l2vpn_evpn": {
            "send_community_standard": true,
            "send_community_extended": true
          }
        }
      }
    },
    "vrfs": {
      "default": {
        "router_id": "172.16.0.1",
        "log_neighbor_changes": true,
        "graseful_restart_stalepath_time": 1800,
        "graseful_restart_restart_time": 300,
        "neighbors": {
          "172.32.3.251": {
            "inherit_peer": "SPINE-PEERS",
            "description": "terraform was here"
          },
          "172.32.3.252": {
            "inherit_peer": "SPINE-PEERS",
            "description": "terraform was here"
          }
        }
      }
    }
  }
}

Output:
{
  "bgp": {
    "asn": 65535,
    "enhanced_error": false,
    "template_peers": [
      {
        "asn": 65536,
        "source_interface": "lo0",
        "address_families": [
          {
            "send_community_standard": true,
            "send_community_extended": true,
            "address_family": "l2vpn_evpn"
          }
        ],
        "template_name": "SPINE-PEERS"
      }
    ],
    "vrfs": [
      {
        "router_id": "172.16.0.1",
        "log_neighbor_changes": true,
        "graseful_restart_stalepath_time": 1800,
        "graseful_restart_restart_time": 300,
        "neighbors": [
          {
            "inherit_peer": "SPINE-PEERS",
            "description": "terraform was here",
            "ip": "172.32.3.251"
          },
          {
            "inherit_peer": "SPINE-PEERS",
            "description": "terraform was here",
            "ip": "172.32.3.252"
          }
        ],
        "vrf": "default"
      }
    ]
  }
}
"""

import sys
import json
from functools import reduce  # forward compatibility for Python 3
import operator


def get_by_path(root, items):
    """Access a nested object in root by item sequence."""
    return reduce(operator.getitem, items, root)


def converter(yaml_data):
    for v in CHANGE_LIST:
        try:
            convert_dict_to_list(yaml_data, v[0], v[1])
        except KeyError:
            pass
        except AttributeError:
            pass


def convert_dict_to_list(parent_data: dict, key_name: str, keys: list):
    data = parent_data[keys[0]]
    if len(keys) == 1:
        # This is the last iteration. data must be dict
        tmp = []
        for k, v in data.items():
            v[key_name] = k
            tmp.append(v)
        parent_data[keys[0]] = tmp
    else:
        if isinstance(data, dict):
            convert_dict_to_list(data, key_name, keys[1:])
        elif isinstance(data, list):
            for v in data:
                convert_dict_to_list(v, key_name, keys[1:])


CHANGE_LIST = [
    ("name", ["bgp", "template_peers"]),
    ("address_family", ["bgp", "template_peers", "address_families"]),
    ("vrf", ["bgp", "vrfs"]),
    ("ip", ["bgp", "vrfs", "neighbors"]),
    ("name", ["ospf"]),
    ("vrf", ["ospf", "vrfs"]),
    ("interface", ["ospf", "vrfs", "interfaces"]),
    ("interfaces_ethernet", ["ospf", "vrfs", "interfaces"]),
    ("name", ["vrfs"]),
    ("name", ["vrfs2"]),
    ("id", ["interfaces_ethernet"]),
    ("id", ["interfaces_loopback"]),
    # ("id", ["interfaces_vlan"]),
]

if __name__ == "__main__":
    input = sys.stdin.read()
    input_json = json.loads(input)
    model = json.loads(input_json["model"])
    # model = json.loads("{\"bgp\": {\"asn\": 65535, \"enhanced_error\": false, \"template_peers\": {\"SPINE-PEERS\": {\"address_families\": {\"l2vpn_evpn\": {\"send_community_extended\": true, \"send_community_standard\": true}}, \"asn\": 65536, \"source_interface\": \"lo0\"}}, \"vrfs\": {\"default\": {\"graseful_restart_restart_time\": 300, \"graseful_restart_stalepath_time\": 1800, \"log_neighbor_changes\": true, \"neighbors\": {\"172.32.3.251\": {\"description\": \"terraform was here\", \"inherit_peer\": \"SPINE-PEERS\"}, \"172.32.3.252\": {\"description\": \"terraform was here\", \"inherit_peer\": \"SPINE-PEERS\"}}, \"router_id\": \"172.16.0.1\"}}}, \"interfaces\": {\"templates\": {\"underlay_interface\": {\"debounce\": 0, \"description\": \"underlay interface\", \"layer\": \"Layer3\"}}}, \"l2vni\": {\"service-a\": {\"apply_to\": [\"mpod-ac-1\"], \"ip_address\": \"10.101.1.1/24\", \"vlan\": 100, \"vni\": 100101, \"vrf\": \"foo\"}, \"service-b\": {\"apply_to\": [\"vpc-pair-1\"], \"ip_address\": \"10.102.1.1/24\", \"vlan\": 102, \"vni\": 100102, \"vrf\": \"bar2\"}, \"service-b2\": {\"apply_to\": [\"vpc-pair-1\"], \"ip_address\": \"10.103.1.1/24\", \"vlan\": 103, \"vni\": 100103, \"vrf\": \"bar2\"}, \"service-test\": {\"apply_to\": [\"vpc-pair-1\"], \"ip_address\": \"10.104.1.1/24\", \"vlan\": 104, \"vni\": 100104, \"vrf\": \"bar3\"}}, \"l3vni\": {\"bar\": {\"rd\": \"auto\", \"vlan\": 3902, \"vni\": 103902}, \"bar2\": {\"rd\": \"auto\", \"vlan\": 3903, \"vni\": 103903}, \"bar3\": {\"rd\": \"1.1.1.1:500\", \"vlan\": 3904, \"vni\": 103904}, \"foo\": {\"rd\": \"auto\", \"vlan\": 3901, \"vni\": 103901}}, \"logging\": {\"default\": {\"levels\": {\"l2fm\": 5}, \"syslog\": {\"foo\": \"bar\"}}}, \"ospf\": {\"underlay-terraform\": {\"vrfs\": {\"default\": {\"adjancency_logging_level\": \"detail\", \"interfaces\": {\"eth1/49\": {\"area\": \"0.0.0.0\"}}, \"router_id\": \"1.1.1.1\"}}}}}")
    # model = input_json["model"]
    # model = json.loads(
    #     '{"bgp":{"asn":65535,"enhanced_error":false,"template_peers":{"SPINE-PEERS":{"address_families":{"l2vpn_evpn":{"send_community_extended":true,"send_community_standard":true}},"asn":65536,"source_interface":"lo0"}},"vrfs":{"default":{"graseful_restart_restart_time":300,"graseful_restart_stalepath_time":1800,"log_neighbor_changes":true,"neighbors":{"172.32.3.251":{"description":"terraform was here","inherit_peer":"SPINE-PEERS"},"172.32.3.252":{"description":"terraform was here","inherit_peer":"SPINE-PEERS"}},"router_id":"172.16.0.1"}}},"interfaces":{"ethernet":{"eth1/41":{"ip_address":"192.168.1.3/31","template":"underlay_interface"},"eth1/42":{"ip_address":"192.168.1.1/31","template":"underlay_interface"}},"templates":{"underlay_interface":{"debounce":0,"description":"underlay interface","layer":"Layer3"}}},"l2vni":{"service-a":{"apply_to":["mpod-ac-1"],"ip_address":"10.101.1.1/24","vlan":100,"vni":100101,"vrf":"foo"},"service-b":{"apply_to":["vpc-pair-1"],"ip_address":"10.102.1.1/24","vlan":102,"vni":100102,"vrf":"bar2"},"service-b2":{"apply_to":["vpc-pair-1"],"ip_address":"10.103.1.1/24","vlan":103,"vni":100103,"vrf":"bar2"},"service-test":{"apply_to":["vpc-pair-1"],"ip_address":"10.104.1.1/24","vlan":104,"vni":100104,"vrf":"bar3"}},"l3vni":{"bar":{"rd":"auto","vlan":3902,"vni":103902},"bar2":{"rd":"auto","vlan":3903,"vni":103903},"bar3":{"rd":"1.1.1.1:500","vlan":3904,"vni":103904},"foo":{"rd":"auto","vlan":3901,"vni":103901}},"logging":{"default":{"levels":{"l2fm":5,"vpc":5},"syslog":{"foo":"bar"}}},"ospf":{"underlay-terraform":{"vrfs":{"default":{"adjancency_logging_level":"detail","interfaces":{"eth1/41":{"area":"0.0.0.0"}},"router_id":"1.1.1.1"}}}}}'
    # )
    converter(model)

    model_json = json.dumps(model)
    output_json = json.dumps({"model": model_json})
    print(output_json)
    # import yaml

    # print(yaml.dump(model, indent=2))
    # with open("model.json", "w") as f:
    #     json.dump(model_json, f)
