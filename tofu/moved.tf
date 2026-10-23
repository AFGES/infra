# reverse-proxy moved to its own module call (module.flatcar_edge)
moved {
  from = module.flatcar_nodes.module.vms["reverse-proxy"]
  to   = module.flatcar_edge.module.vms["reverse-proxy"]
}

moved {
  from = module.flatcar_nodes.module.persistent_disks["reverse-proxy"]
  to   = module.flatcar_edge.module.persistent_disks["reverse-proxy"]
}

moved {
  from = module.flatcar_nodes.proxmox_haresource.vms["reverse-proxy"]
  to   = module.flatcar_edge.proxmox_haresource.vms["reverse-proxy"]
}

moved {
  from = module.flatcar_nodes.proxmox_virtual_environment_file.flatcar_ignition_custom["reverse-proxy"]
  to   = module.flatcar_edge.proxmox_virtual_environment_file.flatcar_ignition["reverse-proxy"]
}

# Flatcar image download moved to its own module (module.flatcar_image)
moved {
  from = module.flatcar_nodes.proxmox_download_file.flatcar_img
  to   = module.flatcar_image.proxmox_download_file.flatcar_img["squirtle"]
}

# Ignition snippets now uploaded to every node, keyed "<vm>/<node>"; existing copies are on squirtle
moved {
  from = module.flatcar_edge.proxmox_virtual_environment_file.flatcar_ignition["reverse-proxy"]
  to   = module.flatcar_edge.proxmox_virtual_environment_file.flatcar_ignition["reverse-proxy/squirtle"]
}

moved {
  from = module.flatcar_registry.proxmox_virtual_environment_file.flatcar_ignition["registry-cache"]
  to   = module.flatcar_registry.proxmox_virtual_environment_file.flatcar_ignition["registry-cache/squirtle"]
}

moved {
  from = module.flatcar_nodes.proxmox_virtual_environment_file.flatcar_ignition["monitoring"]
  to   = module.flatcar_nodes.proxmox_virtual_environment_file.flatcar_ignition["monitoring/squirtle"]
}

moved {
  from = module.flatcar_nodes.proxmox_virtual_environment_file.flatcar_ignition["auth"]
  to   = module.flatcar_nodes.proxmox_virtual_environment_file.flatcar_ignition["auth/squirtle"]
}

moved {
  from = module.flatcar_nodes.proxmox_virtual_environment_file.flatcar_ignition["password-manager"]
  to   = module.flatcar_nodes.proxmox_virtual_environment_file.flatcar_ignition["password-manager/squirtle"]
}

moved {
  from = module.flatcar_nodes.proxmox_virtual_environment_file.flatcar_ignition["n8n"]
  to   = module.flatcar_nodes.proxmox_virtual_environment_file.flatcar_ignition["n8n/squirtle"]
}
