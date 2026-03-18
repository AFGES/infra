variable "id" {
  description = "ID of the VM"
  type        = number
}

variable "name" {
  description = "Name of the VM"
  type        = string
}

variable "start_on_boot" {
  description = "Whether to start VM on node boot"
  type        = bool
  default     = false
}

variable "cpu_cores" {
  description = "Cores to provide to VM"
  type        = number
  default     = 1
}

variable "disk" {
  description = "Drive parameters"
  type = object({
    size    = optional(number, 16),
    file_id = optional(string)
  })
  default = {}
}

variable "memory" {
  description = "Memory to provide to VM (GB)"
  type        = number
  default     = 1
}

variable "machine_type" {
  description = "VM machine type"
  type        = string
  default     = "pc"
}

variable "template" {
  description = "Can be a template"
  type        = bool
  default     = true
}

variable "start_on_provision" {
  description = "Whether to start VM on provision"
  type        = bool
  default     = false
}

variable "password_hash" {
  description = "Hashed password for the admin user (e.g. generated with `openssl passwd -6`)"
  type        = string
  default     = null
  sensitive   = true
}

variable "ssh_authorized_keys" {
  description = "List of SSH public keys to authorize for the admin user"
  type        = list(string)
  default     = []
}

variable "data_disk" {
  description = "Additional data disk for podman volumes (mounted at /var/lib/containers/storage)"
  type = object({
    size         = optional(number, 20),
    datastore_id = optional(string, "ceph")
  })
  default = null
}

variable "user" {
  description = "User name"
  type        = string
  default     = "core"
}
