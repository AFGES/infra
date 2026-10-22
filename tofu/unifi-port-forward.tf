# Port forwards from the UniFi gateway to the reverse-proxy VM
# The VM gets its LAN IP from DHCP, so the forwards follow it on every apply
locals {
  # bpg reports one list per guest NIC (lo, eth0, eth1, docker bridges...); keep the LAN one
  reverse_proxy_lan_ip = one([
    for ip in flatten(module.flatcar_edge.vms["reverse-proxy"].ipv4_addresses) : ip
    if startswith(ip, "192.168.1.")
  ])

  # Mirrors the pangolin/gerbil ports in docker-compose/reverse-proxy/compose.yml
  reverse_proxy_forwards = {
    http         = { port = "80", protocol = "tcp" }
    https        = { port = "443", protocol = "tcp_udp" }
    wireguard    = { port = "51820", protocol = "udp" }
    gerbil-relay = { port = "21820", protocol = "udp" }
  }
}

resource "unifi_port_forward" "reverse_proxy" {
  for_each = local.reverse_proxy_forwards

  name     = "reverse-proxy ${each.key}"
  protocol = each.value.protocol

  wan = {
    interface = "wan"
    port      = each.value.port
  }

  forward = {
    ip   = local.reverse_proxy_lan_ip
    port = each.value.port
  }
}
