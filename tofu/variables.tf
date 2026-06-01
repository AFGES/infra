variable "proxmox_endpoint" {
  description = "Proxmox VE API endpoint"
  type        = string
  default     = "https://pve.afges.eu"
}

variable "proxmox_api_token" {
  description = "Proxmox VE API token"
  type        = string
  sensitive   = true
}

variable "ssh_authorized_keys" {
  description = "SSH public key for the CoreOS default user"
  type        = list(string)
  default     = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOCYJur93Hd1pML/8tfzkWYMlWqGZFnGnbMCKQ89xW7j coles@tuta.io"]
  sensitive   = true
}
