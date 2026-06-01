variable "node_name" {
  description = "Name of the Proxmox node to create the disk container on"
  type        = string
}

variable "vm_id" {
  description = "VM ID for the disk container"
  type        = number
}

variable "name" {
  description = "Name of the disk container VM"
  type        = string
}

variable "disks" {
  description = "List of disks to create in the container"
  type = list(object({
    size         = number
    datastore_id = string
    file_format  = optional(string, "raw")
  }))
  default = []
}
