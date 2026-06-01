terraform {
  required_providers {
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
