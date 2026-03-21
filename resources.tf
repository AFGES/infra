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


module "fedora-coreos-node" {
  source = "./modules/vm"

  depends_on = [module.fedora-coreos-vm]

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

  data_disk = {
    size         = 20
    datastore_id = "ceph"
  }
}
