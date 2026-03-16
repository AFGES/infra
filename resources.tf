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

  password_hash = bcrypt(var.password)
}
