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

output "ha_enabled_nodes" {
  description = "Map of nodes with HA protection enabled"
  value = {
    for k, v in local.ha_enabled_nodes : k => {
      vm_id       = module.vms[k].vm_id
      resource_id = "vm:${module.vms[k].vm_id}"
    }
  }
}

output "ha_configuration" {
  description = "High Availability configuration summary"
  value = {
    enabled           = length(local.ha_enabled_nodes) > 0
    protected_nodes   = keys(local.ha_enabled_nodes)
    unprotected_nodes = [for k, v in var.nodes : k if !coalesce(v.ha_enabled, var.default_ha_enabled)]
    cluster_nodes     = keys(local.ha_nodes)
  }
}
