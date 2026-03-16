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
  default     = "pc"
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

