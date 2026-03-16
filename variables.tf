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

variable "password" {
  description = "Password for the Proxmox VE API token"
  type        = string
  sensitive   = true
}
