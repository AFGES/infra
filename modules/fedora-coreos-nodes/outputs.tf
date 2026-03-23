output "vms" {
  description = "Map of VM details by node name"
  value = {
    for k, v in module.vms : k => {
      vm_id          = v.vm_id
      name           = v.name
      ipv4_addresses = v.ipv4_addresses
    }
  }
}

output "vm_ids" {
  description = "Map of VM IDs by node name"
  value       = { for k, v in module.vms : k => v.vm_id }
}

output "disk_container_ids" {
  description = "Map of disk container VM IDs by node name (only for nodes with persistent disks)"
  value       = { for k, v in module.persistent_disks : k => v.vm_id }
}

output "node_names" {
  description = "List of all node names"
  value       = keys(var.nodes)
}
