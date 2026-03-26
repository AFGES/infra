variable "clone_vm_id" {
  description = "VM ID to clone from. When set, creates a clone of the specified VM instead of importing a disk image."
  type        = number
  default     = null
}

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
  default     = true
}

variable "start_on_provision" {
  description = "Whether to start VM immediately after provisioning"
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
    size         = optional(number, 8),
    file_id      = optional(string),
    format       = optional(string),
    datastore_id = optional(string)
  })
  default = {}
}

variable "memory" {
  description = "Memory to provide to VM (GB)"
  type        = number
  default     = 0.5
}

variable "os_type" {
  description = "VM's OS type"
  type        = string
  default     = "l26"
}

variable "machine_type" {
  description = "VM machine type"
  type        = string
  default     = "q35"
}

variable "template" {
  description = "Create this VM as a template"
  type        = bool
  default     = false
}

variable "ignition_file_id" {
  description = "Proxmox file ID of the Ignition config snippet (e.g. local:snippets/config.ign)"
  type        = string
  default     = null
}

variable "data_disk" {
  description = "Optional second disk for data storage (e.g. podman volumes)"
  type = object({
    size         = optional(number, 20),
    datastore_id = optional(string)
  })
  default = null
}

variable "attached_disks" {
  description = "List of external disks to attach (from persistent-disk module). These disks are not managed by this VM and will persist across rebuilds."
  type = list(object({
    datastore_id      = string
    path_in_datastore = string
    file_format       = string
    size              = number
    interface         = string
  }))
  default = []
}

variable "triggers_replace" {
  description = "A value that, when changed, triggers replacement of this VM (e.g. a template version hash). Useful for forcing clone recreation when the source template is modified."
  type        = any
  default     = null
}

variable "bios" {
  description = "BIOS implementation (seabios for legacy BIOS, ovmf for UEFI)"
  type        = string
  default     = "ovmf"

  validation {
    condition     = contains(["ovmf", "seabios"], var.bios)
    error_message = "BIOS must be either 'ovmf' (UEFI) or 'seabios' (legacy BIOS)."
  }
}

variable "efi_disk" {
  description = "EFI disk configuration (required when using UEFI/ovmf bios)"
  type = object({
    datastore_id      = optional(string, "ceph")
    file_format       = optional(string, "raw")
    type              = optional(string, "4m")
    pre_enrolled_keys = optional(bool, false)
  })
  default = {
    datastore_id      = "ceph"
    file_format       = "raw"
    type              = "4m"
    pre_enrolled_keys = false
  }
}

variable "network_interfaces" {
  description = "List of network interface configurations for the VM"
  type = list(object({
    bridge      = string
    model       = optional(string, "virtio")
    vlan_id     = optional(number)
    mac_address = optional(string)
  }))
  default = [{
    bridge      = "vnet0"
    model       = "virtio"
    vlan_id     = null
    mac_address = null
  }]
}

variable "ip_configs" {
  description = "IP configuration per network interface (one entry per network_interface, in order)"
  type = list(object({
    ipv4_address = optional(string) # CIDR notation or "dhcp"
    ipv4_gateway = optional(string) # omit when using dhcp
  }))
  default = []
}
