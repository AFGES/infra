output "vm_ids" {
  description = "Map of node names to their VM IDs"
  value       = local.vm_ids
}

output "vms" {
  description = "Information about the created VMs"
  value = {
    for k, v in module.vms : k => {
      vm_id          = v.vm_id
      name           = v.name
      ipv4_addresses = v.ipv4_addresses
    }
  }
}

output "persistent_disks" {
  description = "Information about persistent disk containers"
  value = {
    for k, v in module.persistent_disks : k => {
      vm_id = v.vm_id
      disks = v.disks
    }
  }
}

output "ignition_file_id" {
  description = "Map of node names to the Proxmox file ID of their uploaded Ignition configuration"
  value       = { for k, f in proxmox_virtual_environment_file.flatcar_ignition : k => f.id }
}

output "pangolin_sites" {
  description = "Pangolin sites created for opted-in nodes (without secrets)"
  value = {
    for k, s in pangolin_site.nodes : k => {
      id      = s.id
      nice_id = s.nice_id
      newt_id = s.newt_id
    }
  }
}
