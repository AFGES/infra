output "vm_ids" {
  description = "Map of node names to their VM IDs"
  value       = local.vm_ids
}

# output "vms" {
#   description = "Information about the created VMs"
#   value = {
#     for k, v in module.vms : k => {
#       vm_id        = v.id
#       name         = v.name
#       ipv4_address = v.ipv4_address
#       ipv6_address = v.ipv6_address
#     }
#   }
# }

output "persistent_disks" {
  description = "Information about persistent disk containers"
  value = {
    for k, v in module.persistent_disks : k => {
      vm_id = v.vm_id
      disks = v.disks
    }
  }
}

output "flatcar_version" {
  description = "The Flatcar Linux version that was deployed"
  value       = local.flatcar_metadata.version
}

output "ignition_file_id" {
  description = "Proxmox file ID of the uploaded Ignition configuration"
  value       = proxmox_virtual_environment_file.flatcar_ignition.id
}
