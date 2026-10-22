variable "proxmox_endpoint" {
  description = "Proxmox VE API endpoint"
  type        = string
  default     = "https://pve.afges.eu"
}

variable "ssh_authorized_keys" {
  description = "SSH public key for the CoreOS default user"
  type        = list(string)
  default     = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOCYJur93Hd1pML/8tfzkWYMlWqGZFnGnbMCKQ89xW7j coles@tuta.io"]
  sensitive   = true
}

variable "pangolin_bootstrap" {
  description = "Disaster recovery: build reverse-proxy without a Pangolin site, so Pangolin can come back when its API (and so its own site) is gone. Apply targeted, then again without it (see modules/flatcar-vm/README.md)"
  type        = bool
  default     = false
}

variable "pangolin_gate" {
  description = "Wait for the Pangolin API before creating sites and VMs. Set to false (with -refresh=false or -target) to plan while Pangolin is down"
  type        = bool
  default     = true
}
