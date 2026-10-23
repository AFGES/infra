locals {
  vm_ids           = { for k, v in var.nodes : k => 2000 + v.id }
  disk_vm_ids      = { for k, v in var.nodes : k => 9000 + v.id if v.persistent_disk != null }
  nodes_with_disks = { for k, v in var.nodes : k => v if v.persistent_disk != null }
  ha_nodes         = { for name in data.proxmox_virtual_environment_nodes.available.names : name => null }
  ha_enabled_nodes = { for k, v in var.nodes : k => v if coalesce(v.ha_enabled, var.default_ha_enabled) }

  # Effective Proxmox node per VM
  vm_node_names = { for k, v in var.nodes : k => coalesce(v.node_name, var.default_node_name) }

  # Compute effective network interfaces per node
  node_network_interfaces = {
    for k, v in var.nodes : k => coalesce(
      v.network_interfaces,
      v.internet_access == true
      ? [{ bridge = "vnet0", model = "virtio", vlan_id = null, mac_address = null }, { bridge = "vmbr0", model = "virtio", vlan_id = null, mac_address = null }]
      : [{ bridge = "vnet0", model = "virtio", vlan_id = null, mac_address = null }]
    )
  }

  # Newt config per node (written to /etc/newt/config.json), empty without a Pangolin site
  newt_config = {
    for k, v in var.nodes : k => v.pangolin_site ? jsonencode({
      endpoint = "https://pangolin.afges.eu"
      id       = pangolin_site.nodes[k].newt_id
      secret   = pangolin_site.nodes[k].newt_secret
    }) : ""
  }
}

# Auto-discover Proxmox cluster nodes for HA configuration
data "proxmox_virtual_environment_nodes" "available" {}

# Ordering gate: carries var.pangolin_ready so sites and VMs wait for it
resource "terraform_data" "pangolin_ready" {
  input = var.pangolin_ready
}

# Pangolin site (Newt tunnel) per opted-in node
resource "pangolin_site" "nodes" {
  for_each = { for k, v in var.nodes : k => v if v.pangolin_site }
  name     = each.key

  depends_on = [terraform_data.pangolin_ready]
}

# Generate Ignition configuration from Butane template (one per node)
data "ct_config" "flatcar_ignition" {
  for_each = var.nodes

  content = templatefile("${path.module}/butane.yaml.tftpl", {
    ssh_authorized_keys = jsonencode(var.ssh_authorized_keys)
    sops_age_key        = var.sops_age_key
    kernel_modules      = each.value.kernel_modules
    persistent_disk     = each.value.persistent_disk != null
    newt_config         = local.newt_config[each.key]
    registry_cache      = var.registry_cache
  })
  strict = true
}

# Upload Ignition configurations to Proxmox
resource "proxmox_virtual_environment_file" "flatcar_ignition" {
  for_each = var.nodes

  content_type = "snippets"
  datastore_id = "local"
  node_name    = local.vm_node_names[each.key]

  source_raw {
    data      = data.ct_config.flatcar_ignition[each.key].rendered
    file_name = "flatcar-${each.key}.ign"
  }
}

# Create persistent disk containers for nodes that need them
module "persistent_disks" {
  source   = "../persistent-disk"
  for_each = local.nodes_with_disks

  node_name = local.vm_node_names[each.key]
  vm_id     = local.disk_vm_ids[each.key]
  name      = "${each.key}-data"

  disks = [{
    size         = coalesce(each.value.persistent_disk.size, var.default_disk_size)
    datastore_id = "ceph"
    file_format  = coalesce(each.value.persistent_disk.file_format, "raw")
  }]
}

# Create Flatcar VMs
module "vms" {
  source   = "../vm"
  for_each = var.nodes

  depends_on = [module.persistent_disks, terraform_data.pangolin_ready]

  id                 = local.vm_ids[each.key]
  name               = each.key # Map key becomes the VM name directly
  node_name          = local.vm_node_names[each.key]
  machine_type       = coalesce(each.value.machine_type, var.default_machine_type)
  cpu_cores          = coalesce(each.value.cpu_cores, var.default_cpu_cores)
  memory             = coalesce(each.value.memory, var.default_memory)
  start_on_boot      = coalesce(each.value.start_on_boot, var.default_start_on_boot)
  start_on_provision = coalesce(each.value.start_on_provision, var.default_start_on_provision)
  ignition_file_id   = proxmox_virtual_environment_file.flatcar_ignition[each.key].id

  # Use computed network_interfaces based on internet_access flag
  network_interfaces = local.node_network_interfaces[each.key]

  # IP configuration: static IP on vnet0, DHCP on additional interfaces
  ip_configs = concat(
    # First interface (vnet0): static IP based on node ID
    [{
      ipv4_address = "10.20.0.${each.value.id}/24"
    }],
    [
      for i in range(length(local.node_network_interfaces[each.key]) - 1) : {
        ipv4_address = "dhcp"
        ipv4_gateway = null
      }
    ]
  )

  # Rebuild VMs when Butane config changes
  triggers_replace = nonsensitive(sha256(data.ct_config.flatcar_ignition[each.key].rendered))

  disk = {
    size         = 20
    file_id      = var.image_file_ids[local.vm_node_names[each.key]]
    datastore_id = "ceph"
  }

  # Attach persistent disk if this node has one
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

# Purging a VM drops its HA entry; recreate HA with the VM
resource "terraform_data" "ha_trigger" {
  for_each = local.ha_enabled_nodes
  input    = nonsensitive(sha256(data.ct_config.flatcar_ignition[each.key].rendered))
}

# Configure HA resources for enabled nodes
resource "proxmox_haresource" "vms" {
  for_each = local.ha_enabled_nodes

  resource_id  = "vm:${local.vm_ids[each.key]}"
  state        = "started"
  max_restart  = 3
  max_relocate = 2

  depends_on = [module.vms]

  lifecycle {
    replace_triggered_by = [terraform_data.ha_trigger[each.key]]
  }
}
