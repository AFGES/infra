output "vm_id" {
  description = "VM ID of the disk container"
  value       = proxmox_virtual_environment_vm.disk_container.vm_id
}

output "disks" {
  description = "List of disk configurations that can be attached to other VMs"
  value = [
    for disk in proxmox_virtual_environment_vm.disk_container.disk : {
      datastore_id      = disk.datastore_id
      path_in_datastore = disk.path_in_datastore
      file_format       = disk.file_format
      size              = disk.size
      interface         = disk.interface
    }
  ]
}
