output "ipv4_addresses" {
  description = "IPv4 addresses assigned to the VM"
  value       = proxmox_virtual_environment_vm.this.ipv4_addresses
}

output "vm_id" {
  description = "The ID of the VM"
  value       = proxmox_virtual_environment_vm.this.vm_id
}

output "name" {
  description = "The name of the VM"
  value       = proxmox_virtual_environment_vm.this.name
}
