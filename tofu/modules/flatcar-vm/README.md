# flatcar-vm

Provisions [Flatcar Container Linux](https://www.flatcar.org/) VMs on Proxmox VE, each running
[doco-cd](https://github.com/kimdre/doco-cd) to deploy its Docker Compose stack from this repository (GitOps).

## What it does

For every entry in `var.nodes`, the module:

1. Renders an Ignition config from `butane.yaml.tftpl` (via the `poseidon/ct` provider) and uploads it
   to the `local` datastore of the VM's Proxmox node as a snippet (`flatcar-<name>.ign`).
2. Creates a VM (`../vm` module) from the latest **Flatcar stable** Proxmox image. The image is downloaded
   once per Proxmox node hosting a VM and verified against the release SHA512 digest.
3. Optionally creates a persistent data disk (`../persistent-disk` module) on Ceph and attaches it.
4. Optionally creates a [Pangolin](https://github.com/fosrl/pangolin) site and injects its Newt credentials into doco-cd.
5. Registers the VM as a Proxmox HA resource (unless disabled).

### Inside the VM

The Butane template configures:

- the `core` user with `var.ssh_authorized_keys`;
- the French console keymap (`KEYMAP=fr`);
- for nodes with a `persistent_disk` only: `/dev/sdb` partitioned (label `docker-data`, XFS) and mounted on
  `/var/lib/docker/volumes`, so Docker volumes survive VM rebuilds. Neither the partition table nor the
  filesystem is wiped on reprovisioning. Without a persistent disk, volumes live on the OS disk and are lost
  on rebuild;
- `doco-cd.service`, a container polling `https://github.com/AFGES/infra.git` (`main` branch) with
  `target: %l`, i.e. the VM **hostname**. Each node therefore deploys `docker-compose/<node name>/`;
- `/etc/default/doco-cd` (mode `0600`) passed to doco-cd as env file, with `PASS_ENV=true` so the values
  are available to the Compose stacks:
  - `SOPS_AGE_KEY` when `var.sops_age_key` is set (decrypts SOPS-encrypted files in the stack);
  - `NEWT_ID` / `NEWT_SECRET` when the node has `pangolin_site = true`.

## Conventions

| Item                  | Value                                                        |
| --------------------- | ------------------------------------------------------------ |
| VM ID                 | `2000 + id` (e.g. `id = 1` gives `2001`)                     |
| Disk container VM ID  | `9000 + id`                                                  |
| VM name / hostname    | map key in `var.nodes`                                       |
| IPv4 on first NIC     | `10.20.0.<id>/24` (static, on `vnet0`)                       |
| Additional NICs       | DHCP                                                         |
| OS disk               | 20 GB on `ceph`, `scsi0`                                     |
| Persistent disk       | on `ceph`, attached from `scsi1` (seen as `/dev/sdb`)        |

`id` must be unique and between 1 and 999.

Networking defaults to a single `vnet0` interface. `internet_access = true` adds a second interface on
`vmbr0` (DHCP). Setting `network_interfaces` overrides both.

## Lifecycle

- VMs are **replaced** whenever their rendered Ignition config changes (`triggers_replace` is the config's
  SHA256). This includes changes to the template, SSH keys, SOPS key or Pangolin credentials.
- The Flatcar version is resolved at plan time from the stable channel. The image is downloaded with
  `overwrite = false`, so a new release does not replace existing VMs by itself; Flatcar updates itself in place.
- Persistent disks live in separate disk-container VMs and are not destroyed when a VM is rebuilt.

## Usage

```hcl
module "flatcar_nodes" {
  source = "./modules/flatcar-vm"

  ssh_authorized_keys = var.ssh_authorized_keys
  sops_age_key        = data.sops_file.secrets.data["sops_age_key"]

  default_memory = 2

  nodes = {
    reverse-proxy = {
      id              = 1
      persistent_disk = { size = 20 }
      internet_access = true
      pangolin_site   = true
    }
  }
}
```

Then add the stack in `docker-compose/reverse-proxy/` and push to `main`.

## Requirements

| Provider            | Version     |
| ------------------- | ----------- |
| `bpg/proxmox`       | `>= 0.98.0` |
| `hashicorp/http`    | `>= 3.0`    |
| `poseidon/ct`       | `>= 0.13.0` |
| `stackopshq/pangolin` | `~> 1.5`  |

The Proxmox cluster must provide a `local` datastore accepting `snippets` and `import` content, a `ceph`
datastore, and the `vnet0` / `vmbr0` bridges.

## Inputs

| Name                         | Type           | Default      | Description                                                        |
| ---------------------------- | -------------- | ------------ | ------------------------------------------------------------------ |
| `ssh_authorized_keys`        | `list(string)` | required     | SSH public keys for the `core` user                                |
| `sops_age_key`               | `string`       | `""`         | Age key given to doco-cd as `SOPS_AGE_KEY` (sensitive)             |
| `nodes`                      | `map(object)`  | required     | Node definitions, see below                                        |
| `default_cpu_cores`          | `number`       | `2`          | CPU cores                                                          |
| `default_memory`             | `number`       | `2`          | Memory in GB                                                       |
| `default_disk_size`          | `number`       | `20`         | Persistent disk size in GB                                         |
| `default_node_name`          | `string`       | `"squirtle"` | Proxmox node hosting VMs, their Ignition snippet and disk container |
| `default_start_on_boot`      | `bool`         | `true`       | Start VM when the Proxmox node boots                               |
| `default_start_on_provision` | `bool`         | `true`       | Start VM right after creation                                      |
| `default_machine_type`       | `string`       | `"q35"`      | QEMU machine type                                                  |
| `default_ha_enabled`         | `bool`         | `true`       | Register VMs as HA resources                                       |

### `nodes` attributes

Every optional attribute without its own default falls back to the matching `default_*` variable.

| Attribute            | Type           | Default | Description                                                         |
| -------------------- | -------------- | ------- | ------------------------------------------------------------------- |
| `id`                 | `number`       | required | 1-999, drives VM ID, disk ID and IP                                |
| `node_name`          | `string`       | —       | Proxmox node hosting the VM, its Ignition snippet and disk container |
| `cpu_cores`          | `number`       | —       | CPU cores                                                           |
| `memory`             | `number`       | —       | Memory in GB                                                        |
| `machine_type`       | `string`       | —       | QEMU machine type                                                   |
| `start_on_boot`      | `bool`         | —       | Start on Proxmox node boot                                          |
| `start_on_provision` | `bool`         | —       | Start after creation                                                |
| `ha_enabled`         | `bool`         | —       | Register as HA resource                                             |
| `internet_access`    | `bool`         | `false` | Add a DHCP interface on `vmbr0`                                     |
| `pangolin_site`      | `bool`         | `false` | Create a Pangolin site and pass `NEWT_ID` / `NEWT_SECRET` to doco-cd |
| `persistent_disk`    | `object`       | `null`  | `{ size = optional(number), file_format = optional(string, "raw") }` |
| `network_interfaces` | `list(object)` | `null`  | `{ bridge, model = "virtio", vlan_id, mac_address }`, overrides `internet_access` |

## Outputs

| Name               | Description                                                   |
| ------------------ | ------------------------------------------------------------- |
| `vm_ids`           | Node name to VM ID                                            |
| `vms`              | Node name to `{ vm_id, name, ipv4_addresses }`                |
| `persistent_disks` | Node name to `{ vm_id, disks }` for nodes with a data disk    |
| `flatcar_version`  | Deployed Flatcar stable version                               |
| `ignition_file_id` | Node name to Proxmox file ID of its Ignition config           |
| `pangolin_sites`   | Node name to `{ id, nice_id, newt_id }` (no secrets)          |
