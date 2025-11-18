variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type        = string
  sensitive   = true
}

variable "server_name" {
  description = "Name of the server"
  type        = string
  default     = "chatbot-server"
}

variable "server_type" {
  description = "Hetzner server type"
  type        = string
  default     = "cx53"
}

variable "location" {
  description = "Hetzner datacenter location"
  type        = string
  default     = "fsn1"
}

variable "image" {
  description = "OS image for the server"
  type        = string
  default     = "ubuntu-22.04"
}

variable "ssh_key_name" {
  description = "Name of the SSH key in Hetzner Cloud"
  type        = string
  default     = "alex@tpad"
}

variable "ssh_public_key" {
  description = "SSH public key content"
  type        = string
  default     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAmm9jDoXxpMFSGUYFUCk56TaPPTxMRdgnTY9FCBwjF3 alex@tpad"
}

variable "server_domain" {
  description = "Server domain name"
  type        = string
  default     = "chatbot.k8s-demo.de"
}
