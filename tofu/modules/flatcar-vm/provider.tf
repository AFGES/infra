terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.98.0"
    }
    ct = {
      source  = "poseidon/ct"
      version = ">= 0.13.0"
    }
    pangolin = {
      source  = "stackopshq/pangolin"
      version = "~> 1.5"
    }
  }
}
