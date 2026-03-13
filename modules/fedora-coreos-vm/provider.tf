terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.90.0"
    }
    ct = {
      source  = "poseidon/ct"
      version = "0.14.0"
    }
  }
}
