# Read encrypted secrets using SOPS
data "sops_file" "secrets" {
  source_file = "secrets.yaml"
}

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

  # No data_disk on template - clones will attach persistent disks instead
  # data_disk = null

  ssh_authorized_keys = var.ssh_authorized_keys
  sops_age_key        = data.sops_file.secrets.data["sops_age_key"]
}

# Fedora CoreOS cloned VMs with optional persistent disks
# Uses the fedora-coreos-nodes module to create multiple VMs from the template
# VM IDs: 2000 + id (e.g., id=1 becomes 2001)
# Disk container IDs: 9000 + id (e.g., id=1 becomes 9001)
module "fedora_coreos_nodes" {
  source = "./modules/fedora-coreos-nodes"

  template_vm_id   = module.fedora-coreos-vm.vm_id
  template_version = module.fedora-coreos-vm.template_version
  ignition_file_id = module.fedora-coreos-vm.ignition_file_id

  # Cluster-wide defaults (can be overridden per-node)
  default_cpu_cores          = 2
  default_memory             = 2
  default_disk_size          = 20
  default_node_name          = "squirtle"
  default_start_on_boot      = true
  default_start_on_provision = true
  default_machine_type       = "q35"

  nodes = {
    # First node with persistent disk
    # VM ID: 2001, Disk Container: 9001
    reverse-proxy = {
      id = 1
      persistent_disk = {
        size = 20
      }
    }

    # Example: Add more nodes by uncommenting and configuring below
    # node2 = {
    #   id = 2  # VM ID: 2002, Disk Container: 9002
    #   cpu_cores = 4
    #   memory = 4
    #   persistent_disk = {
    #     size = 50
    #   }
    # }
    #
    # worker = {
    #   id = 3  # VM ID: 2003, no persistent disk
    #   cpu_cores = 2
    #   # No persistent_disk = ephemeral node
    # }
  }
}
