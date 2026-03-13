terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.97.1"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = "terraform@pve!provider=${var.proxmox_api_token}"

  ssh {
    agent    = true
    username = "root"
  }
}
