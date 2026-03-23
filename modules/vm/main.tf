resource "terraform_data" "triggers" {
  input = var.triggers_replace
}

resource "proxmox_virtual_environment_vm" "this" {
  node_name = "squirtle"
  vm_id     = var.id

  name        = "${var.name}.afges.eu"
  description = "${var.name} VM, managed by OpenTofu"
  tags        = ["opentofu"]

  keyboard_layout = "fr"

  bios    = var.bios
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

  dynamic "clone" {
    for_each = var.clone_vm_id != null ? [var.clone_vm_id] : []
    content {
      vm_id = clone.value
      full  = true
    }
  }

  dynamic "efi_disk" {
    for_each = var.bios == "ovmf" ? [var.efi_disk] : []
    content {
      datastore_id      = efi_disk.value.datastore_id
      file_format       = efi_disk.value.file_format
      type              = efi_disk.value.type
      pre_enrolled_keys = efi_disk.value.pre_enrolled_keys
    }
  }

  dynamic "disk" {
    for_each = var.clone_vm_id == null ? [var.disk] : []
    content {
      interface    = "scsi0"
      size         = disk.value.size
      import_from  = disk.value.file_id
      file_format  = disk.value.format
      datastore_id = disk.value.datastore_id
    }
  }

  dynamic "disk" {
    for_each = var.data_disk != null ? [var.data_disk] : []
    content {
      interface    = "scsi1"
      size         = disk.value.size
      datastore_id = disk.value.datastore_id
    }
  }

  # Attached disks from external disk containers
  # These disks persist across VM rebuilds
  dynamic "disk" {
    for_each = var.attached_disks
    content {
      datastore_id      = disk.value.datastore_id
      path_in_datastore = disk.value.path_in_datastore
      file_format       = disk.value.file_format
      size              = disk.value.size
      interface         = disk.value.interface
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
    datastore_id        = coalesce(var.disk.datastore_id, "local")
    vendor_data_file_id = var.ignition_file_id
  }

  # Ignore changes to the network
  ## MAC address is generated on every apply, causing
  ## TF to think this needs to be rebuilt on every apply
  lifecycle {
    replace_triggered_by = [terraform_data.triggers]
    ignore_changes = [
      started,
      network_device,
      initialization,
      ipv4_addresses,
      ipv6_addresses,
      network_interface_names,
    ]
  }
}
