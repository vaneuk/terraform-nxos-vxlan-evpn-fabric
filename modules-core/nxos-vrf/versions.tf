terraform {
  required_version = ">= 1.0.0"

  required_providers {
    nxos = {
      source  = "netascode/nxos"
      version = ">= 0.1.0"
    }
  }
  experiments = [module_variable_optional_attrs]
}


