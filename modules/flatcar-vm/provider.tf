terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.98.0"
    }
    http = {
      source  = "hashicorp/http"
      version = ">= 3.0"
    }
    ct = {
      source  = "poseidon/ct"
      version = ">= 0.13.0"
    }
  }
}
