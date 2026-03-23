# Auto-discover all available nodes in the Proxmox cluster
data "proxmox_virtual_environment_nodes" "available" {}

# Calculate actual VM IDs with prefixes
# VM IDs: 2000 + id (e.g., id=1 becomes 2001)
# Disk container IDs: 9000 + id (e.g., id=1 becomes 9001)
locals {
  # VM IDs for all nodes
  vm_ids = {
    for k, v in var.nodes : k => 2000 + v.id
  }

  # Disk container IDs only for nodes with persistent disks
  disk_vm_ids = {
    for k, v in var.nodes : k => 9000 + v.id
    if v.persistent_disk != null
  }

  # Filter nodes that need persistent disks
  nodes_with_disks = {
    for k, v in var.nodes : k => v
    if v.persistent_disk != null
  }

  # Extract online nodes for HA group
  # Use all nodes with null priority (no preference)
  ha_nodes = {
    for name in data.proxmox_virtual_environment_nodes.available.names :
    name => null
  }

  # Filter nodes that have HA enabled
  ha_enabled_nodes = {
    for k, v in var.nodes : k => v
    if coalesce(v.ha_enabled, var.default_ha_enabled)
  }
}

# Create persistent disk containers for nodes that need them
# These are "VM shells" that hold disks but never start
module "persistent_disks" {
  for_each = local.nodes_with_disks
  source   = "../persistent-disk"

  node_name = coalesce(each.value.node_name, var.default_node_name)
  vm_id     = local.disk_vm_ids[each.key]
  name      = "${each.key}-data"

  disks = [{
    size         = coalesce(each.value.persistent_disk.size, var.default_disk_size)
    datastore_id = "ceph"
    file_format  = coalesce(each.value.persistent_disk.file_format, "raw")
  }]
}

# Create cloned VMs for all nodes
module "vms" {
  for_each = var.nodes
  source   = "../vm"

  depends_on = [module.persistent_disks]

  # Trigger VM replacement when template changes
  triggers_replace = var.template_version

  id           = local.vm_ids[each.key]
  name         = each.key # Map key becomes the VM name directly
  machine_type = coalesce(each.value.machine_type, var.default_machine_type)

  # Clone from the template VM
  clone_vm_id = var.template_vm_id

  start_on_provision = coalesce(each.value.start_on_provision, var.default_start_on_provision)
  start_on_boot      = coalesce(each.value.start_on_boot, var.default_start_on_boot)
  template           = false

  cpu_cores = coalesce(each.value.cpu_cores, var.default_cpu_cores)
  memory    = coalesce(each.value.memory, var.default_memory)

  # Disk configuration (datastore for cloud-init/ignition drive)
  disk = {
    datastore_id = "ceph"
  }

  ignition_file_id = var.ignition_file_id

  # Attach persistent disk if this node has one
  # Uses lookup to safely check if the node exists in nodes_with_disks
  attached_disks = lookup(local.nodes_with_disks, each.key, null) != null ? [
    for idx, disk in module.persistent_disks[each.key].disks : {
      datastore_id      = disk.datastore_id
      path_in_datastore = disk.path_in_datastore
      file_format       = disk.file_format
      size              = disk.size
      # Assign from scsi1 onwards (scsi0 is the OS disk)
      interface = "scsi${idx + 1}"
    }
  ] : []
}

# Create HA resources for VMs with HA enabled
# Note: In Proxmox VE 9+, HA groups have been replaced by HA rules
# For simple HA protection, we just need to register resources with the HA manager
resource "proxmox_virtual_environment_haresource" "vms" {
  for_each = local.ha_enabled_nodes

  depends_on = [module.vms]

  resource_id = "vm:${module.vms[each.key].vm_id}"
  state       = "started"
  comment     = "HA-protected ${each.key} (managed by OpenTofu)"

  # Restart limits
  max_restart  = 3 # Try restarting 3 times on same node
  max_relocate = 2 # Try relocating 2 times to different nodes
}
