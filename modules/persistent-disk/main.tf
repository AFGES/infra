# This module creates a "disk container" VM that is never started
# It exists solely to hold data disks that can be attached to other VMs
# When the actual VM is rebuilt, these disks remain untouched

resource "proxmox_virtual_environment_vm" "disk_container" {
  node_name = var.node_name
  vm_id     = var.vm_id
  name      = var.name

  started = false
  on_boot = false
  template = false

  description = "Disk container for ${var.name}, managed by OpenTofu. Never start this VM."
  tags        = ["opentofu", "disk-container"]

  # Minimal configuration - this VM is never started
  cpu {
    cores = 1
  }

  memory {
    dedicated = 512
  }

  # Create data disks
  dynamic "disk" {
    for_each = var.disks
    content {
      datastore_id = disk.value.datastore_id
      interface    = "scsi${disk.key}"
      size         = disk.value.size
      file_format  = lookup(disk.value, "file_format", "raw")
    }
  }

  # No network needed for disk containers
  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  operating_system {
    type = "l26"
  }

  lifecycle {
    # Prevent accidental deletion of disks
    prevent_destroy = false
    
    # Ignore changes that don't affect the disks
    ignore_changes = [
      started,
      on_boot,
    ]
  }
}
