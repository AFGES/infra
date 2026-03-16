# SDN Zone - VXLAN
resource "proxmox_virtual_environment_sdn_zone_vxlan" "proxmox_vxlan" {
  id    = "vxlan1"
  ipam  = "pve"
  peers = var.peers

  depends_on = [
    proxmox_virtual_environment_sdn_applier.finalizer
  ]
}

# Basic VNet (Simple)
resource "proxmox_virtual_environment_sdn_vnet" "proxmox_vnet" {
  id   = "vnet0"
  tag  = 1
  zone = proxmox_virtual_environment_sdn_zone_vxlan.proxmox_vxlan.id

  depends_on = [
    proxmox_virtual_environment_sdn_applier.finalizer
  ]
}

# SDN Applier - Applies SDN configuration changes
resource "proxmox_virtual_environment_sdn_applier" "example_applier" {
  lifecycle {
    replace_triggered_by = [
      proxmox_virtual_environment_sdn_zone_vxlan.proxmox_vxlan,
      proxmox_virtual_environment_sdn_vnet.proxmox_vnet,
    ]
  }

  depends_on = [
    proxmox_virtual_environment_sdn_zone_vxlan.proxmox_vxlan,
    proxmox_virtual_environment_sdn_vnet.proxmox_vnet,
  ]
}


resource "proxmox_virtual_environment_sdn_applier" "finalizer" {
}
