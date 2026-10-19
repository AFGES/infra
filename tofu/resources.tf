# Read encrypted secrets using SOPS
data "sops_file" "secrets" {
  source_file = "secrets.yaml"
}

module "network" {
  source = "./modules/network"
  peers  = ["192.168.3.1", "192.168.3.2", "192.168.3.3"]
}


# Flatcar Linux VMs with doco-cd installed
# Uses the flatcar-vm module to create VMs directly from Flatcar stable images
# VM IDs: 2000 + id (e.g., id=1 becomes 2001)
# Disk container IDs: 9000 + id (e.g., id=1 becomes 9001)
module "flatcar_nodes" {
  source = "./modules/flatcar-vm"

  ssh_authorized_keys = var.ssh_authorized_keys
  sops_age_key        = data.sops_file.secrets.data["sops_age_key"]

  # Cluster-wide defaults (can be overridden per-node)
  default_cpu_cores          = 2
  default_memory             = 2
  default_disk_size          = 20
  default_node_name          = "squirtle"
  default_start_on_boot      = true
  default_start_on_provision = true
  default_machine_type       = "q35"
  default_ha_enabled         = true

  nodes = {
    reverse-proxy = {
      id = 1
      # gerbil (Pangolin) needs kernel WireGuard; loaded by the host so the container needs no SYS_MODULE
      kernel_modules = ["wireguard"]
      persistent_disk = {
        size = 20
      }
      internet_access = true
      pangolin_site   = true
    }

    monitoring = {
      id = 2
      persistent_disk = {
        size = 100
      }
      internet_access = true
      pangolin_site   = true
    }

    auth = {
      id     = 3
      memory = 4
      persistent_disk = {
        size = 20
      }
      internet_access = true
    }

    password-manager = {
      id = 4
      persistent_disk = {
        size = 20
      }
      internet_access = true
    }

    n8n = {
      id     = 5
      memory = 4
      persistent_disk = {
        size = 20
      }
      internet_access = true
    }
  }
}
