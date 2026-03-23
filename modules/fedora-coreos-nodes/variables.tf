variable "template_vm_id" {
  description = "VM ID of the Fedora CoreOS template to clone from"
  type        = number
}

variable "template_version" {
  description = "Template version hash for triggering VM replacement when template changes"
  type        = any
}

variable "ignition_file_id" {
  description = "Proxmox file ID of the Ignition config snippet (e.g. local:snippets/config.ign)"
  type        = string
}

# Cluster-wide defaults

variable "default_cpu_cores" {
  description = "Default CPU cores for all VMs (can be overridden per-VM)"
  type        = number
  default     = 2
}

variable "default_memory" {
  description = "Default memory in GB for all VMs (can be overridden per-VM)"
  type        = number
  default     = 2
}

variable "default_disk_size" {
  description = "Default persistent disk size in GB (can be overridden per-VM)"
  type        = number
  default     = 20
}

variable "default_node_name" {
  description = "Default Proxmox node name where VMs will be created (can be overridden per-VM)"
  type        = string
  default     = "squirtle"
}

variable "default_start_on_boot" {
  description = "Default behavior for starting VMs on Proxmox node boot (can be overridden per-VM)"
  type        = bool
  default     = true
}

variable "default_start_on_provision" {
  description = "Default behavior for starting VMs immediately after provisioning (can be overridden per-VM)"
  type        = bool
  default     = true
}

variable "default_machine_type" {
  description = "Default VM machine type (can be overridden per-VM)"
  type        = string
  default     = "q35"
}

variable "default_ha_enabled" {
  description = "Default behavior for High Availability protection (can be overridden per-node)"
  type        = bool
  default     = true
}

# Node definitions

variable "nodes" {
  description = <<-EOT
    Map of node configurations. The map key will be used as the VM name.
    Each node will get VM ID = 2000 + id and disk container ID = 9000 + id.

    Example:
    nodes = {
      web = {
        id = 1  # VM ID: 2001, Disk: 9001
        cpu_cores = 4
        persistent_disk = {
          size = 50
        }
      }
      worker = {
        id = 2  # VM ID: 2002, no disk
      }
    }
  EOT

  type = map(object({
    id                 = number
    node_name          = optional(string)
    cpu_cores          = optional(number)
    memory             = optional(number)
    machine_type       = optional(string)
    start_on_boot      = optional(bool)
    start_on_provision = optional(bool)
    ha_enabled         = optional(bool)
    persistent_disk = optional(object({
      size        = optional(number)
      file_format = optional(string, "raw")
    }))
  }))

  validation {
    condition = alltrue([
      for k, v in var.nodes : v.id >= 1 && v.id <= 999
    ])
    error_message = "Node IDs must be between 1 and 999 (VM IDs will be 2001-2999, disk container IDs will be 9001-9999)."
  }

  validation {
    condition     = length(var.nodes) == length(distinct([for k, v in var.nodes : v.id]))
    error_message = "All node IDs must be unique."
  }
}
