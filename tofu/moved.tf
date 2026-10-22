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
