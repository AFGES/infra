output "fedora_coreos_node_ipv4" {
  description = "IPv4 addresses of the fedora-coreos-node VM"
  value       = module.fedora-coreos-node.ipv4_addresses
}
