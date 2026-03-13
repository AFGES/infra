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
  }

  kvm_arguments = var.kvm_arguments

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
