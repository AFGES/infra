output "fedora_coreos_nodes" {
  description = "Map of all Fedora CoreOS node details (VM IDs, names, IP addresses)"
  value       = module.fedora_coreos_nodes.vms
}
