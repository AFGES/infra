# flatcar-vm

Provisions [Flatcar Container Linux](https://www.flatcar.org/) VMs on Proxmox VE, each running
[doco-cd](https://github.com/kimdre/doco-cd) to deploy its Docker Compose stack from this repository (GitOps).

## What it does

For every entry in `var.nodes`, the module:

1. Renders an Ignition config from `butane.yaml.tftpl` (via the `poseidon/ct` provider) and uploads it
   to the `local` datastore of the VM's Proxmox node as a snippet (`flatcar-<name>.ign`).
2. Creates a VM (`../vm` module) from the Flatcar image given in `var.image_file_ids` for the VM's Proxmox
   node (see the [`flatcar-image`](../flatcar-image/README.md) module).
3. Optionally creates a persistent data disk (`../persistent-disk` module) on Ceph and attaches it.
4. Optionally creates a [Pangolin](https://github.com/fosrl/pangolin) site and writes its Newt credentials
   to the VM.
5. Registers the VM as a Proxmox HA resource (unless disabled).

### Inside the VM

The Butane template configures:

- the `core` user with `var.ssh_authorized_keys`;
- the French console keymap (`KEYMAP=fr`);
- `net.ipv4.ip_nonlocal_bind = 1`, so Docker can bind ports to the `vnet0` IP before the interface is up;
- the node's `kernel_modules`, loaded at boot via `/etc/modules-load.d/flatcar-vm.conf`;
- for nodes with a `persistent_disk` only: the `scsi1` disk (by-id path) partitioned (label `docker-data`,
  XFS) and mounted on `/var/lib/docker/volumes`, so Docker volumes survive VM rebuilds. Neither the partition
  table nor the filesystem is wiped on reprovisioning. Without a persistent disk, volumes live on the OS disk and are lost
  on rebuild;
- `doco-cd.service`, a container polling `https://github.com/AFGES/infra.git` (`main` branch) with
  `target: %l`, i.e. the VM **hostname**. Each node therefore deploys `docker-compose/<node name>/`.
  `SOPS_AGE_KEY` is passed to doco-cd when `var.sops_age_key` is set (decrypts SOPS-encrypted files in the
  stack);
- for nodes with `pangolin_site = true` only: `/etc/newt/config.json` (mode `0600`, root), the Newt config
  `{"endpoint": "https://pangolin.afges.eu", "id": …, "secret": …}`. The stack's `newt` service mounts it
  read-only and points `CONFIG_FILE` at it:

  ```yaml
  newt:
    environment:
      CONFIG_FILE: /etc/newt/config.json
    volumes:
      - /etc/newt/config.json:/etc/newt/config.json:ro
  ```

## Conventions

| Item                  | Value                                                        |
| --------------------- | ------------------------------------------------------------ |
| VM ID                 | `2000 + id` (e.g. `id = 1` gives `2001`)                     |
| Disk container VM ID  | `9000 + id`                                                  |
| VM name / hostname    | map key in `var.nodes`                                       |
| IPv4 on first NIC     | `10.20.0.<id>/24` (static, on `vnet0`)                       |
| Additional NICs       | DHCP                                                         |
| OS disk               | 20 GB on `ceph`, `scsi0`                                     |
| Persistent disk       | on `ceph`, attached from `scsi1`                             |

`id` must be unique and between 1 and 999.

Networking defaults to a single `vnet0` interface. `internet_access = true` adds a second interface on
`vmbr0` (DHCP). Setting `network_interfaces` overrides both.

## Lifecycle

- VMs are **replaced** whenever their rendered Ignition config changes (`triggers_replace` is the config's
  SHA256). This includes changes to the template, SSH keys, SOPS key or Pangolin credentials.
- Replacing a VM purges its HA entry on Proxmox, so the HA resource is replaced with it (`replace_triggered_by`
  on the same config hash).
- Pangolin sites and VMs wait for `var.pangolin_ready`. Pass a value that is only known once Pangolin answers
  (e.g. the `id` of an `http` data source polling its API) to create them after the Pangolin host is up.
- Persistent disks live in separate disk-container VMs and are not destroyed when a VM is rebuilt.

## Pangolin outage and disaster recovery

In the root configuration, reverse-proxy (`module.flatcar_edge`) serves the Pangolin API that creates every
site, including its own. `module.flatcar_nodes` waits for `data.http.pangolin_ready` (60 × 10 s, about 10 min,
then the postcondition fails). Two root variables work around this:

| Variable             | Default | Effect                                                                               |
| -------------------- | ------- | ------------------------------------------------------------------------------------ |
| `pangolin_gate`      | `true`  | `false` drops `data.http.pangolin_ready`; `flatcar_nodes` gets `pangolin_ready = ""` |
| `pangolin_bootstrap` | `false` | `true` builds reverse-proxy without a Pangolin site (no `/etc/newt/config.json`)     |

The stackopshq/pangolin provider probes `GET /v1/org/<org>` when it is configured. If Pangolin is unreachable
it only warns, but a rejected API key is an error. `PANGOLIN_SKIP_HEALTH_PROBE=1` skips the probe.

### Pangolin down, nothing to change

When the edge VM is unchanged, the gate is read at plan time, so every plan waits about 10 min and then fails.
Plan without it. Skip refresh so the existing `pangolin_site` resources are not read:

```sh
tofu plan -var pangolin_gate=false -refresh=false
```

`-target` on resources outside Pangolin works too.

### Rebuilding reverse-proxy from scratch

Use this when the Pangolin data on reverse-proxy's persistent disk (disk container 9001) is lost.
`pangolin_site["reverse-proxy"]` then cannot be recreated, and since its Newt config is part of the Ignition
config, the VM cannot be rebuilt either.

Run the steps in this order. In a plan where reverse-proxy is replaced and its `pangolin_site` is new,
OpenTofu destroys the VM before creating the site, so the site create hits a dead API and the apply fails
halfway. Create the site on its own first.

1. Bring Pangolin up without a site for reverse-proxy, using the Proxmox IP endpoint (`pve.afges.eu` goes
   through Pangolin):

   ```sh
   PANGOLIN_SKIP_HEALTH_PROBE=1 tofu apply -var pangolin_bootstrap=true \
     -var proxmox_endpoint=https://192.168.1.106:8006/ \
     -target=module.flatcar_edge -target=unifi_port_forward.reverse_proxy
   ```

   The targeted graph contains no `pangolin_site` instance and no gate, so it makes no Pangolin API call.
2. Stop doco-cd on reverse-proxy (the rebuild changed its host key, so `ssh-keygen -R` it first):

   ```sh
   ssh core@<reverse-proxy LAN IP> sudo systemctl stop doco-cd
   ```

   Without a config `newt` crash-loops, so Pangolin flaps (see below). Step 5 rebuilds the VM and doco-cd
   comes back.
3. Run Pangolin's initial setup (admin account, `afges` organization). Create an integration API key and
   store it as `pangolin_api_key` in `secrets.yaml`.
4. Wait until `curl https://api.pangolin.afges.eu/v1/` returns `{"message":"Healthy"}`, then create the
   reverse-proxy site alone:

   ```sh
   tofu apply -var proxmox_endpoint=https://192.168.1.106:8006/ \
     -target='module.flatcar_edge.pangolin_site.nodes'
   ```

5. Apply in full (`tofu apply -var proxmox_endpoint=https://192.168.1.106:8006/`). reverse-proxy is rebuilt
   with its Newt config, the gate waits for it, then the other nodes follow. Their sites were lost with the
   old Pangolin, so they are recreated, which rebuilds those VMs. If refreshing them fails, remove them from
   the state first (`tofu state rm 'module.flatcar_nodes.pangolin_site.nodes'`).

### Newt crash loops and doco-cd

This applies to any change, not only recovery. When a `newt` container crash-loops (e.g. no
`/etc/newt/config.json`), doco-cd marks the deploy failed (`service newt has a restarting container`) and
recreates the whole stack about every 3 min, Pangolin and Traefik included on reverse-proxy. So when the
Newt credential format changes, pushing the compose change to `main` before the VMs carry the new config
makes every stack flap: rebuild the edge site first and keep the window short.

VM rebuilds change SSH host keys. Run `ssh-keygen -R <ip>` before connecting.

## Usage

```hcl
module "flatcar_nodes" {
  source = "./modules/flatcar-vm"

  ssh_authorized_keys = var.ssh_authorized_keys
  sops_age_key        = data.sops_file.secrets.data["sops_age_key"]
  image_file_ids      = module.flatcar_image.file_ids

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

| Provider              | Version     |
| --------------------- | ----------- |
| `bpg/proxmox`         | `>= 0.98.0` |
| `poseidon/ct`         | `>= 0.13.0` |
| `stackopshq/pangolin` | `~> 1.5`    |

The Proxmox cluster must provide a `local` datastore accepting `snippets` content, a `ceph` datastore, and
the `vnet0` / `vmbr0` bridges.

## Inputs

| Name                         | Type           | Default      | Description                                                        |
| ---------------------------- | -------------- | ------------ | ------------------------------------------------------------------ |
| `ssh_authorized_keys`        | `list(string)` | required     | SSH public keys for the `core` user                                |
| `sops_age_key`               | `string`       | `""`         | Age key given to doco-cd as `SOPS_AGE_KEY` (sensitive)             |
| `image_file_ids`             | `map(string)`  | required     | Proxmox node name to Flatcar image file ID (`flatcar-image` output) |
| `pangolin_ready`             | `string`       | `""`         | Pangolin sites and VMs wait for this value                         |
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
| `kernel_modules`     | `list(string)` | `[]`    | Kernel modules loaded at boot                                       |
| `pangolin_site`      | `bool`         | `false` | Create a Pangolin site and write `/etc/newt/config.json`            |
| `persistent_disk`    | `object`       | `null`  | `{ size = optional(number), file_format = optional(string, "raw") }` |
| `network_interfaces` | `list(object)` | `null`  | `{ bridge, model = "virtio", vlan_id, mac_address }`, overrides `internet_access` |

## Outputs

| Name               | Description                                                   |
| ------------------ | ------------------------------------------------------------- |
| `vm_ids`           | Node name to VM ID                                            |
| `vms`              | Node name to `{ vm_id, name, ipv4_addresses }`                |
| `persistent_disks` | Node name to `{ vm_id, disks }` for nodes with a data disk    |
| `ignition_file_id` | Node name to Proxmox file ID of its Ignition config           |
| `pangolin_sites`   | Node name to `{ id, nice_id, newt_id }` (no secrets)          |
