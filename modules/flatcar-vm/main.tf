locals {
  vm_ids           = { for k, v in var.nodes : k => 2000 + v.id }
  disk_vm_ids      = { for k, v in var.nodes : k => 9000 + v.id if v.persistent_disk != null }
  nodes_with_disks = { for k, v in var.nodes : k => v if v.persistent_disk != null }
  ha_nodes         = { for name in data.proxmox_virtual_environment_nodes.available.names : name => null }
  ha_enabled_nodes = { for k, v in var.nodes : k => v if coalesce(v.ha_enabled, var.default_ha_enabled) }

  flatcar_metadata = {
    for match in regexall("([A-Z0-9_]+)=[\"']?([^\"'\n\r]+)[\"']?", data.http.flatcar_current_metadata.response_body) :
    lower(trimprefix(match[0], "FLATCAR_")) => match[1]
  }

  # Extract SHA512 hash from DIGESTS file
  # Format: "SHA512 (flatcar_production_qemu_image.img.bz2) = <hash>"
  all_hex_strings = flatten(regexall("(?m)^([a-f0-9]+)", data.http.flatcar_digests.response_body))

  # 2. Map them by their known lengths
  flatcar_digests = {
    md5    = [for s in local.all_hex_strings : s if length(s) == 32][0]
    sha1   = [for s in local.all_hex_strings : s if length(s) == 40][0]
    sha512 = [for s in local.all_hex_strings : s if length(s) == 128][0]
  }

}

# Fetch the current Flatcar Linux stable version
data "http" "flatcar_current_metadata" {
  url = "https://stable.release.flatcar-linux.net/amd64-usr/current/version.txt"
}

# Fetch DIGESTS file for hash verification
data "http" "flatcar_digests" {
  url = "https://stable.release.flatcar-linux.net/amd64-usr/${local.flatcar_metadata.version}/flatcar_production_proxmoxve_image.img.DIGESTS"
}

# Auto-discover Proxmox cluster nodes for HA configuration
data "proxmox_virtual_environment_nodes" "available" {}

# Generate Ignition configuration from Butane template
data "ct_config" "flatcar_ignition" {
  content = templatefile("${path.module}/butane.yaml.tftpl", {
    ssh_authorized_keys = jsonencode(var.ssh_authorized_keys)
    sops_age_key        = var.sops_age_key
  })
  strict = true
}

# Upload Ignition configuration to Proxmox
resource "proxmox_virtual_environment_file" "flatcar_ignition" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.default_node_name

  source_raw {
    data      = data.ct_config.flatcar_ignition.rendered
    file_name = "flatcar-cluster.ign"
  }
}

# Download Flatcar Linux image to Proxmox with hash verification
resource "proxmox_virtual_environment_download_file" "flatcar_img" {
  content_type       = "import"
  datastore_id       = "local"
  node_name          = var.default_node_name
  url                = "https://stable.release.flatcar-linux.net/amd64-usr/${local.flatcar_metadata.version}/flatcar_production_proxmoxve_image.img"
  file_name          = "flatcar-production-proxmoxve.qcow2"
  overwrite          = false
  checksum           = local.flatcar_digests.sha512
  checksum_algorithm = "sha512"
  verify             = true
}

# Create persistent disk containers for nodes that need them
module "persistent_disks" {
  source   = "../persistent-disk"
  for_each = local.nodes_with_disks

  node_name = coalesce(each.value.node_name, var.default_node_name)
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

  depends_on = [module.persistent_disks]

  id                 = local.vm_ids[each.key]
  name               = each.key # Map key becomes the VM name directly
  machine_type       = coalesce(each.value.machine_type, var.default_machine_type)
  cpu_cores          = coalesce(each.value.cpu_cores, var.default_cpu_cores)
  memory             = coalesce(each.value.memory, var.default_memory)
  start_on_boot      = coalesce(each.value.start_on_boot, var.default_start_on_boot)
  start_on_provision = coalesce(each.value.start_on_provision, var.default_start_on_provision)
  ignition_file_id   = proxmox_virtual_environment_file.flatcar_ignition.id

  disk = {
    size         = 20
    file_id      = proxmox_virtual_environment_download_file.flatcar_img.id
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

# Configure HA resources for enabled nodes
resource "proxmox_virtual_environment_haresource" "vms" {
  for_each = local.ha_enabled_nodes

  resource_id  = "vm:${local.vm_ids[each.key]}"
  state        = "started"
  max_restart  = 3
  max_relocate = 2

  depends_on = [module.vms]
}
