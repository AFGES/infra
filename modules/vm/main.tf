resource "proxmox_virtual_environment_vm" "this" {
  node_name = "squirtle"
  vm_id     = var.id

  name        = "${var.name}.afges.eu"
  description = "${var.name} VM, managed by OpenTofu"
  tags        = ["opentofu"]

  keyboard_layout = "fr"

  machine = var.machine_type
  on_boot = var.start_on_boot
  started = var.start_on_provision

  template = var.template

  agent {
    enabled = true
  }

  cpu {
    cores = var.cpu_cores
    type  = "host"
  }

  disk {
    interface = "scsi0"
    size      = var.disk.size

    import_from = var.disk.file_id
    file_format = var.disk.format

    datastore_id = var.disk.datastore_id
  }

  dynamic "disk" {
    for_each = var.data_disk != null ? [var.data_disk] : []
    content {
      interface    = "scsi1"
      size         = disk.value.size
      datastore_id = disk.value.datastore_id
    }
  }

  memory {
    dedicated = 1024 * var.memory
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }
  operating_system {
    type = var.os_type
  }

  vga {
    type = "std"
  }

  initialization {
    datastore_id = var.disk.datastore_id
    user_account {
      username = "core"
      password = "afges1234"
    }
    vendor_data_file_id = var.ignition_file_id
  }

  # Ignore changes to the network
  ## MAC address is generated on every apply, causing
  ## TF to think this needs to be rebuilt on every apply
  lifecycle {
    ignore_changes = [
      started,
      network_device,
    ]
  }
}
