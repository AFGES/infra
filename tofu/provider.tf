terraform {
  required_providers {
    ovh = {
      source  = "ovh/ovh"
      version = ">= 2.0"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.98.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "~> 1.4"
    }
  }
}

provider "ovh" {
  endpoint  = "ovh-eu"
  client_id = data.sops_file.secrets.data["ovh.client_id"]
  client_secret = data.sops_file.secrets.data["ovh.client_secret"]
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = "terraform@pve!provider=${data.sops_file.secrets.data["proxmox_api_token"]}"

  # Evaluates to true if the host is an IPv4 address, and false if it is a domain name.
  insecure  = can(regex("^(https?://)?(\\d{1,3}\\.){3}\\d{1,3}(:\\d+)?(/.*)?$", var.proxmox_endpoint))

  ssh {
    agent    = true
    username = "root"
  }
}
