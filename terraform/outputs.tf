output "server_ip" {
  description = "Public IP address of the chatbot server"
  value       = hcloud_server.chatbot.ipv4_address
}

output "server_ipv6" {
  description = "IPv6 address of the chatbot server"
  value       = hcloud_server.chatbot.ipv6_address
}

output "server_id" {
  description = "ID of the chatbot server"
  value       = hcloud_server.chatbot.id
}

output "server_status" {
  description = "Status of the chatbot server"
  value       = hcloud_server.chatbot.status
}

output "server_domain" {
  description = "Domain name of the chatbot server"
  value       = var.server_domain
}
