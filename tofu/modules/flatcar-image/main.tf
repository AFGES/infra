locals {
  flatcar_metadata = {
    for match in regexall("([A-Z0-9_]+)=[\"']?([^\"'\n\r]+)[\"']?", data.http.flatcar_current_metadata.response_body) :
    lower(trimprefix(match[0], "FLATCAR_")) => match[1]
  }

  # Extract SHA512 hash from DIGESTS file
  # Format: "SHA512 (flatcar_production_qemu_image.img.bz2) = <hash>"
  all_hex_strings = flatten(regexall("(?m)^([a-f0-9]+)", data.http.flatcar_digests.response_body))

  # 2. Map them by their known lengths
  flatcar_digests = {
    md5    = [for s in local.all_hex_strings : s if length(s) == 32][0]
    sha1   = [for s in local.all_hex_strings : s if length(s) == 40][0]
    sha512 = [for s in local.all_hex_strings : s if length(s) == 128][0]
  }
}

# Fetch the current Flatcar Linux stable version
data "http" "flatcar_current_metadata" {
  url = "https://stable.release.flatcar-linux.net/amd64-usr/current/version.txt"
}

# Fetch DIGESTS file for hash verification
data "http" "flatcar_digests" {
  url = "https://stable.release.flatcar-linux.net/amd64-usr/${local.flatcar_metadata.version}/flatcar_production_proxmoxve_image.img.DIGESTS"
}

# Download Flatcar Linux image with hash verification, on every Proxmox node hosting a VM
resource "proxmox_download_file" "flatcar_img" {
  for_each = var.node_names

  content_type       = "import"
  datastore_id       = "local"
  node_name          = each.key
  url                = "https://stable.release.flatcar-linux.net/amd64-usr/${local.flatcar_metadata.version}/flatcar_production_proxmoxve_image.img"
  file_name          = "flatcar-production-proxmoxve.qcow2"
  overwrite          = false
  checksum           = local.flatcar_digests.sha512
  checksum_algorithm = "sha512"
  verify             = true
}
