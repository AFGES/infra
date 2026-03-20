output "ignition_file_id" {
  description = "Proxmox file ID of the generated Ignition config snippet"
  value       = proxmox_virtual_environment_file.coreos_ignition.id
}
