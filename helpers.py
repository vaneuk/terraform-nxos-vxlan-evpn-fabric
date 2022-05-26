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

from copy import deepcopy


def convert_dicts_to_lists(yaml_data):
    data = deepcopy(yaml_data)
    for v in CHANGE_LIST:
        try:
            converter(data, v[0], v[1])
        except KeyError:
            pass
        except AttributeError:
            pass
    return data


def converter(parent_data: dict, key_name: str, keys: list):
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
            converter(data, key_name, keys[1:])
        elif isinstance(data, list):
            for v in data:
                converter(v, key_name, keys[1:])


CHANGE_LIST = [
    ("name", ["bgp", "template_peers"]),
    ("address_family", ["bgp", "template_peers", "address_families"]),
    ("vrf", ["bgp", "vrfs"]),
    ("ip", ["bgp", "vrfs", "neighbors"]),
    ("name", ["ospf"]),
    ("vrf", ["ospf", "vrfs"]),
    ("interface", ["ospf", "vrfs", "interfaces"]),
    # ("interfaces_ethernet", ["ospf", "vrfs", "interfaces"]),
    # ("name", ["vrfs"]),
    # ("id", ["interfaces_ethernet"]),
    ("id", ["interfaces_loopback"]),
]
