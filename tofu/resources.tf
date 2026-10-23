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
# reverse-proxy (Pangolin) is its own module call so the other nodes can wait for it
locals {
  # Cluster-wide defaults (can be overridden per-node)
  flatcar_defaults = {
    cpu_cores          = 2
    memory             = 2
    disk_size          = 20
    node_name          = "squirtle"
    start_on_boot      = true
    start_on_provision = true
    machine_type       = "q35"
    ha_enabled         = true
  }

  # doco-cd and newt from the latest AFGES sysext-bakery sysexts, kept up to date by systemd-sysupdate
  sysexts = true

  # Zot pull-through cache on registry-cache (vnet0 only)
  registry_cache = {
    url        = "http://10.20.0.6:5000"
    registries = ["docker.io", "ghcr.io"]
  }
}

# Flatcar image, downloaded once per Proxmox node hosting a VM
module "flatcar_image" {
  source = "./modules/flatcar-image"

  node_names = [local.flatcar_defaults.node_name]
}

module "flatcar_edge" {
  source = "./modules/flatcar-vm"

  ssh_authorized_keys = var.ssh_authorized_keys
  sops_age_key        = data.sops_file.secrets.data["sops_age_key"]
  image_file_ids      = module.flatcar_image.file_ids
  # The cache waits for Pangolin, so the edge must not wait for the cache; containerd falls back to upstream
  registry_cache = merge(local.registry_cache, { wait = false })

  default_cpu_cores          = local.flatcar_defaults.cpu_cores
  default_memory             = local.flatcar_defaults.memory
  default_disk_size          = local.flatcar_defaults.disk_size
  default_node_name          = local.flatcar_defaults.node_name
  default_start_on_boot      = local.flatcar_defaults.start_on_boot
  default_start_on_provision = local.flatcar_defaults.start_on_provision
  default_machine_type       = local.flatcar_defaults.machine_type
  default_ha_enabled         = local.flatcar_defaults.ha_enabled

  nodes = {
    reverse-proxy = {
      id = 1
      # gerbil (Pangolin) needs kernel WireGuard; loaded by the host so the container needs no SYS_MODULE
      kernel_modules = ["wireguard"]
      persistent_disk = {
        size = 20
      }
      # Same NICs as internet_access = true, with MACs pinned so a rebuild keeps the DHCP lease
      # (the UniFi port forwards target this IP)
      network_interfaces = [
        { bridge = "vnet0", mac_address = "BC:24:11:E1:02:E2" },
        { bridge = "vmbr0", mac_address = "BC:24:11:8A:D1:3B" },
      ]
      # No site in bootstrap mode: the site lives in the Pangolin this VM serves
      pangolin_site = !var.pangolin_bootstrap
    }
  }
}

# Registry cache: own call so it does not wait for itself at boot (no registry_cache)
# Waits for Pangolin like the other nodes (its own site); the edge does not wait for it
module "flatcar_registry" {
  source = "./modules/flatcar-vm"

  ssh_authorized_keys = var.ssh_authorized_keys
  sops_age_key        = data.sops_file.secrets.data["sops_age_key"]
  image_file_ids      = module.flatcar_image.file_ids
  pangolin_ready      = try(data.http.pangolin_ready[0].id, "")
  sysexts             = local.sysexts

  default_cpu_cores          = local.flatcar_defaults.cpu_cores
  default_memory             = local.flatcar_defaults.memory
  default_disk_size          = local.flatcar_defaults.disk_size
  default_node_name          = local.flatcar_defaults.node_name
  default_start_on_boot      = local.flatcar_defaults.start_on_boot
  default_start_on_provision = local.flatcar_defaults.start_on_provision
  default_machine_type       = local.flatcar_defaults.machine_type
  default_ha_enabled         = local.flatcar_defaults.ha_enabled

  nodes = {
    registry-cache = {
      id = 6
      persistent_disk = {
        size = 50
      }
      internet_access = true
      pangolin_site   = true
    }
  }
}

# Pangolin must answer again before the other nodes' sites are created
# The forwards follow the edge VM's IP, so they already wait for it; depending on
# module.flatcar_edge as a whole creates a cycle with its HA replacement
# var.pangolin_gate = false skips it, so plans don't wait ~10 min while Pangolin is down
data "http" "pangolin_ready" {
  count = var.pangolin_gate ? 1 : 0

  url                = "https://api.pangolin.afges.eu/v1/"
  request_timeout_ms = 5000
  depends_on         = [unifi_port_forward.reverse_proxy]

  retry {
    attempts     = 60
    min_delay_ms = 10000
    max_delay_ms = 10000
  }

  lifecycle {
    postcondition {
      condition     = self.status_code == 200 && strcontains(self.response_body, "Healthy")
      error_message = "Pangolin integration API not ready"
    }
  }
}

module "flatcar_nodes" {
  source = "./modules/flatcar-vm"

  ssh_authorized_keys = var.ssh_authorized_keys
  sops_age_key        = data.sops_file.secrets.data["sops_age_key"]
  image_file_ids      = module.flatcar_image.file_ids
  pangolin_ready      = try(data.http.pangolin_ready[0].id, "")
  registry_cache      = local.registry_cache
  sysexts             = local.sysexts

  default_cpu_cores          = local.flatcar_defaults.cpu_cores
  default_memory             = local.flatcar_defaults.memory
  default_disk_size          = local.flatcar_defaults.disk_size
  default_node_name          = local.flatcar_defaults.node_name
  default_start_on_boot      = local.flatcar_defaults.start_on_boot
  default_start_on_provision = local.flatcar_defaults.start_on_provision
  default_machine_type       = local.flatcar_defaults.machine_type
  default_ha_enabled         = local.flatcar_defaults.ha_enabled

  nodes = {
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
      pangolin_site   = true
    }

    password-manager = {
      id = 4
      persistent_disk = {
        size = 20
      }
      internet_access = true
      pangolin_site   = true
    }

    n8n = {
      id     = 5
      memory = 4
      persistent_disk = {
        size = 20
      }
      internet_access = true
      pangolin_site   = true
    }
  }
}
