output "flatcar_nodes" {
  description = "Map of all Flatcar Linux node details (VM IDs, names, IP addresses)"
  value       = merge(module.flatcar_edge.vms, module.flatcar_registry.vms, module.flatcar_nodes.vms)
}

output "reverse_proxy_lan_ip" {
  description = "LAN IPv4 of the reverse-proxy VM, target of the UniFi port forwards"
  value       = local.reverse_proxy_lan_ip
}
