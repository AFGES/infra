output "ignition_file_id" {
  description = "Proxmox file ID of the generated Ignition config snippet"
  value       = proxmox_virtual_environment_file.coreos_ignition.id
}

output "template_version" {
  description = "Hash that changes when the template's image or Ignition config is modified, used to trigger clone replacement"
  value       = sha256(join(",", [local.download_sum, data.ct_config.coreos_ignition.rendered]))
}
