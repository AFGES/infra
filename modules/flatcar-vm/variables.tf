variable "ssh_authorized_keys" {
  description = "List of SSH public keys to authorize for the core user"
  type        = list(string)
}

variable "sops_age_key" {
  description = "SOPS AGE key for decrypting secrets in doco-cd configurations"
  type        = string
  sensitive   = true
  default     = ""
}

variable "nodes" {
  description = "Map of node configurations. Each key becomes the node hostname, and each value contains the node's configuration."
  type = map(object({
    id                 = number
    node_name          = optional(string)
    cpu_cores          = optional(number)
    memory             = optional(number)
    machine_type       = optional(string)
    start_on_boot      = optional(bool)
    start_on_provision = optional(bool)
    ha_enabled         = optional(bool)
    internet_access    = optional(bool, false)
    persistent_disk = optional(object({
      size        = optional(number)
      file_format = optional(string, "raw")
    }))
    network_interfaces = optional(list(object({
      bridge      = string
      model       = optional(string, "virtio")
      vlan_id     = optional(number)
      mac_address = optional(string)
    })))
  }))

  validation {
    condition = alltrue([
      for k, v in var.nodes : v.id >= 1 && v.id <= 999
    ])
    error_message = "Node IDs must be between 1 and 999 (VM IDs will be 2001-2999, disk container IDs will be 9001-9999)."
  }

  validation {
    condition = length(var.nodes) == length(distinct([
      for k, v in var.nodes : v.id
    ]))
    error_message = "All node IDs must be unique."
  }
}

variable "default_cpu_cores" {
  description = "Default number of CPU cores for VMs"
  type        = number
  default     = 2
}

variable "default_memory" {
  description = "Default memory allocation for VMs in GB"
  type        = number
  default     = 2
}

variable "default_disk_size" {
  description = "Default size for persistent disks in GB"
  type        = number
  default     = 20
}

variable "default_node_name" {
  description = "Default Proxmox node name to create VMs on"
  type        = string
  default     = "squirtle"
}

variable "default_start_on_boot" {
  description = "Default value for whether VMs should start on node boot"
  type        = bool
  default     = true
}

variable "default_start_on_provision" {
  description = "Default value for whether VMs should start immediately after provisioning"
  type        = bool
  default     = true
}

variable "default_machine_type" {
  description = "Default machine type for VMs"
  type        = string
  default     = "q35"
}

variable "default_ha_enabled" {
  description = "Default value for whether HA should be enabled for VMs"
  type        = bool
  default     = true
}
