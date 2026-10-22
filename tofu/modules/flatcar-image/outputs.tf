output "version" {
  description = "The current Flatcar Linux stable version"
  value       = local.flatcar_metadata.version
}

output "file_ids" {
  description = "Map of Proxmox node names to the file ID of their downloaded Flatcar image"
  value       = { for k, f in proxmox_download_file.flatcar_img : k => f.id }
}
