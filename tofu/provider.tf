terraform {
  required_providers {
    http = {
      source  = "hashicorp/http"
      version = ">= 3.0"
    }
    ovh = {
      source  = "ovh/ovh"
      version = ">= 2.0"
    }
    pangolin = {
      source  = "stackopshq/pangolin"
      version = "~> 1.5"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.98.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "~> 1.4"
    }
    unifi = {
      source  = "ubiquiti-community/unifi"
      version = "~> 0.59"
    }
  }
}

provider "ovh" {
  endpoint      = "ovh-eu"
  client_id     = data.sops_file.secrets.data["ovh.client_id"]
  client_secret = data.sops_file.secrets.data["ovh.client_secret"]
}

provider "unifi" {
  api_url = data.sops_file.secrets.data["unifi.api_url"]
  api_key = data.sops_file.secrets.data["unifi.api_key"]

  # The gateway serves a self-signed certificate
  allow_insecure = true
}

provider "pangolin" {
  url     = "https://api.pangolin.afges.eu"
  api_key = data.sops_file.secrets.data["pangolin_api_key"]
  org_id  = "afges"
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = "terraform@pve!provider=${data.sops_file.secrets.data["proxmox_api_token"]}"

  # Evaluates to true if the host is an IPv4 address, and false if it is a domain name.
  insecure = can(regex("^(https?://)?(\\d{1,3}\\.){3}\\d{1,3}(:\\d+)?(/.*)?$", var.proxmox_endpoint))

  ssh {
    agent    = true
    username = "root"
  }
}
