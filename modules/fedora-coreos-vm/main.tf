locals {
  metadata = jsondecode(data.http.coreos_stable_metadata.response_body)

  coreos_proxmoxve_stable = local.metadata.architectures.x86_64.artifacts.proxmoxve.formats["qcow2.xz"].disk
  download_url            = local.coreos_proxmoxve_stable.location
  download_sum            = local.coreos_proxmoxve_stable.sha256
}

data "ct_config" "coreos_ignition" {
  strict = true
  content = templatefile("${path.module}/butane.yaml.tftpl", {
    ssh_admin_username  = "admin"
    hostname            = "coreos"
    password_hash       = var.password_hash
    ssh_authorized_keys = var.ssh_authorized_keys
  })
}

data "http" "coreos_stable_metadata" {
  url = "https://builds.coreos.fedoraproject.org/streams/stable.json"
}

resource "proxmox_virtual_environment_file" "coreos_ignition" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "squirtle"

  source_raw {
    data      = data.ct_config.coreos_ignition.rendered
    file_name = "fedora-coreos-${var.name}.ign"
  }
}

resource "proxmox_virtual_environment_download_file" "coreos_img" {
  content_type = "import"
  datastore_id = "local"
  node_name    = "squirtle"

  url      = local.download_url
  checksum = local.download_sum

  checksum_algorithm      = "sha256"
  decompression_algorithm = "zst"

  overwrite = false

  file_name = "fedora-coreos-proxmoxve.qcow2"
}

module "coreos-vm" {
  source = "../vm"

  id           = var.id
  name         = var.name
  machine_type = var.machine_type

  start_on_boot      = var.start_on_boot
  start_on_provision = var.start_on_provision

  cpu_cores = var.cpu_cores
  memory    = var.memory

  template = var.template

  disk = {
    size = var.disk.size

    file_id      = proxmox_virtual_environment_download_file.coreos_img.id
    datastore_id = "ceph"
  }

  data_disk = var.data_disk

  ignition_file_id = proxmox_virtual_environment_file.coreos_ignition.id
}
