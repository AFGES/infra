# Flatcar VM Module

This module provisions Flatcar Linux VMs on Proxmox with doco-cd (Docker CD) installed for automated container deployments.

## Features

- **Flatcar Linux**: Automatically downloads and provisions latest stable Flatcar Linux images
- **Doco-CD Integration**: Pre-configured with doco-cd service for GitOps-style container deployments
- **Persistent Disks**: Optional persistent data disks for Docker volumes that survive VM rebuilds
- **High Availability**: Built-in HA support with configurable restart/relocate policies
- **ID Convention**: Predictable VM IDs (2000+) and disk container IDs (9000+)
- **Ignition Config**: Uses Butane templates to generate Ignition configurations

## Usage

```hcl
module "flatcar_cluster" {
  source = "./modules/flatcar-vm"
  
  ssh_authorized_keys = ["ssh-ed25519 AAAA..."]
  sops_age_key        = data.sops_file.secrets.data["age_key"]
  
  nodes = {
    flatcar-01 = {
      id          = 1  # VM ID: 2001, Disk: 9001
      cpu_cores   = 4
      memory      = 8
      persistent_disk = {
        size = 50  # GB
      }
    }
    flatcar-02 = {
      id         = 2  # VM ID: 2002
      node_name  = "bulbasaur"
      ha_enabled = false
    }
    flatcar-03 = {
      id = 3  # VM ID: 2003
      # Uses all defaults
    }
  }
}
```

## ID Convention

- **VM IDs**: `2000 + node.id` (e.g., id=1 → VM ID 2001)
- **Disk Container IDs**: `9000 + node.id` (e.g., id=1 → Disk ID 9001)
- **Valid Range**: Node IDs must be between 1-999

## Key Differences from Fedora CoreOS

1. **Butane Variant**: Uses `flatcar` variant v1.2.0 instead of `fcos` v1.5.0
2. **Image Source**: Downloads from Flatcar stable channel
3. **QEMU Guest Agent**: Built-in, no sysext needed
4. **Direct Provisioning**: Creates VMs directly from downloaded image (no template/clone)

## Inputs

### Required Variables

| Name | Type | Description |
|------|------|-------------|
| `ssh_authorized_keys` | `list(string)` | SSH public keys for the `core` user |
| `nodes` | `map(object)` | Map of node configurations (see below) |

### Optional Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `sops_age_key` | `string` | `""` | SOPS AGE key for decrypting secrets |
| `default_cpu_cores` | `number` | `2` | Default CPU cores per VM |
| `default_memory` | `number` | `2` | Default memory in GB |
| `default_disk_size` | `number` | `20` | Default persistent disk size in GB |
| `default_node_name` | `string` | `"squirtle"` | Default Proxmox node |
| `default_start_on_boot` | `bool` | `true` | Start VMs on node boot |
| `default_start_on_provision` | `bool` | `true` | Start VMs immediately after creation |
| `default_machine_type` | `string` | `"q35"` | Default VM machine type |
| `default_ha_enabled` | `bool` | `true` | Enable HA by default |

### Node Object Structure

```hcl
{
  id                 = number           # Required: 1-999
  node_name          = optional(string) # Proxmox node name
  cpu_cores          = optional(number)
  memory             = optional(number) # GB
  machine_type       = optional(string)
  start_on_boot      = optional(bool)
  start_on_provision = optional(bool)
  ha_enabled         = optional(bool)
  persistent_disk = optional(object({
    size        = optional(number)      # GB
    file_format = optional(string, "raw")
  }))
}
```

## Outputs

| Name | Description |
|------|-------------|
| `vm_ids` | Map of node names to VM IDs |
| `vms` | VM information (ID, name, IP addresses) |
| `persistent_disks` | Persistent disk information |
| `flatcar_version` | Deployed Flatcar Linux version |
| `ignition_file_id` | Proxmox Ignition config file ID |

## Doco-CD Configuration

The module configures doco-cd to:
- Poll Git repositories at `https://github.com/afges/%l.git` (where `%l` is the hostname)
- Mount Docker socket for container management
- Use persistent volume `doco-cd.volume` for state
- Decrypt secrets using SOPS AGE key if provided

## Persistent Disks

When `persistent_disk` is configured:
- A separate disk container VM is created (ID: 9000 + node.id)
- Disk is formatted as XFS and mounted at `/var/lib/docker/volumes`
- Disk persists across VM rebuilds
- Automatically attached as `scsi1` (scsi0 is the OS disk)

## Requirements

- Proxmox provider >= 0.98.0
- HTTP provider >= 3.0
- ct (CoreOS Transpiler) provider >= 0.13.0
- Access to `stable.release.flatcar-linux.net`
- Ceph storage for VMs
- Local storage for images

## Notes

- VMs are named with `.afges.eu` suffix automatically (handled by vm module)
- French keyboard layout is configured by default (`KEYMAP=fr`)
- Docker service is enabled and started automatically
- The persistent disk expects `/dev/sdb` - ensure no conflicts with other disks
