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

# Subnet for vnet0 (no SNAT - internet access via vmbr0)
resource "proxmox_virtual_environment_sdn_subnet" "vnet0" {
  cidr            = "10.20.0.0/24"
  vnet            = proxmox_virtual_environment_sdn_vnet.proxmox_vnet.id
  dns_zone_prefix = "afges.eu"

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
      proxmox_virtual_environment_sdn_subnet.vnet0,
    ]
  }

  depends_on = [
    proxmox_virtual_environment_sdn_zone_vxlan.proxmox_vxlan,
    proxmox_virtual_environment_sdn_vnet.proxmox_vnet,
    proxmox_virtual_environment_sdn_subnet.vnet0,
  ]
}


resource "proxmox_virtual_environment_sdn_applier" "finalizer" {
}
