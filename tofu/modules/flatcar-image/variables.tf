variable "node_names" {
  description = "Proxmox nodes to download the Flatcar image to (every node hosting a Flatcar VM)"
  type        = set(string)
}
