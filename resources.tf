module "network" {
  source = "./modules/network"
  peers  = ["192.168.3.1", "192.168.3.2", "192.168.3.3"]
}


module "fedora-coreos-vm" {
  source = "./modules/fedora-coreos-vm"

  id           = 900
  name         = "fedora-coreos"
  machine_type = "q35"

  cpu_cores = 2
  memory    = 2

  disk = {
    size = 20
  }

  data_disk = {
    size         = 20
    datastore_id = "ceph"
  }

  ssh_authorized_keys = var.ssh_authorized_keys
}

# Persistent data disk for fedora-coreos-node
# This disk survives VM rebuilds when the template changes
module "fedora-coreos-node-data" {
  source = "./modules/persistent-disk"

  node_name = "squirtle"
  vm_id     = 911
  name      = "fedora-coreos-node-data"

  disks = [
    {
      size         = 20
      datastore_id = "ceph"
      file_format  = "raw"
    }
  ]
}


module "fedora-coreos-node" {
  source = "./modules/vm"

  depends_on = [module.fedora-coreos-vm, module.fedora-coreos-node-data]

  triggers_replace = module.fedora-coreos-vm.template_version

  id           = 901
  name         = "fedora-coreos-node"
  machine_type = "q35"

  clone_vm_id = 900

  start_on_provision = true
  start_on_boot      = true
  template           = false

  cpu_cores = 2
  memory    = 2

  # datastore_id is used by the initialization block (cloud-init/ignition drive)
  # and must point to a storage that supports the "images" content type
  disk = {
    datastore_id = "ceph"
  }

  ignition_file_id = module.fedora-coreos-vm.ignition_file_id

  # Attach persistent data disk that survives VM rebuilds
  attached_disks = [
    for idx, disk in module.fedora-coreos-node-data.disks : {
      datastore_id      = disk.datastore_id
      path_in_datastore = disk.path_in_datastore
      file_format       = disk.file_format
      size              = disk.size
      # Assign from scsi1 onwards (scsi0 is the OS disk)
      interface = "scsi${idx + 1}"
    }
  ]
}
