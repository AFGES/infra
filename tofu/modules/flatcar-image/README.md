# flatcar-image

Downloads the latest **Flatcar stable** Proxmox image to the `local` datastore of each given Proxmox node,
for the [`flatcar-vm`](../flatcar-vm/README.md) module.

## What it does

1. Resolves the current stable version from `https://stable.release.flatcar-linux.net/amd64-usr/current/version.txt`.
2. Fetches the release `DIGESTS` file and extracts the SHA512 of the Proxmox image.
3. Downloads `flatcar_production_proxmoxve_image.img` as `flatcar-production-proxmoxve.qcow2` (`import`
   content) on every node in `var.node_names`, verified against that digest.

It lives outside `flatcar-vm` so several `flatcar-vm` calls share one download per Proxmox node.

## Lifecycle

- The version is resolved at plan time. The image is downloaded with `overwrite = false`, so a new release
  does not replace the file nor the VMs built from it; Flatcar updates itself in place.

## Usage

```hcl
module "flatcar_image" {
  source = "./modules/flatcar-image"

  node_names = ["squirtle"]
}

module "flatcar_nodes" {
  source = "./modules/flatcar-vm"

  image_file_ids = module.flatcar_image.file_ids
  # ...
}
```

Every Proxmox node hosting a `flatcar-vm` VM must be listed in `node_names`.

## Requirements

| Provider         | Version     |
| ---------------- | ----------- |
| `bpg/proxmox`    | `>= 0.98.0` |
| `hashicorp/http` | `>= 3.0`    |

The Proxmox nodes must provide a `local` datastore accepting `import` content.

## Inputs

| Name         | Type          | Default  | Description                                |
| ------------ | ------------- | -------- | ------------------------------------------ |
| `node_names` | `set(string)` | required | Proxmox nodes to download the image to     |

## Outputs

| Name       | Description                                          |
| ---------- | ---------------------------------------------------- |
| `version`  | Current Flatcar stable version                       |
| `file_ids` | Proxmox node name to file ID of the downloaded image |
