data "hcloud_ssh_key" "default" {
  name = var.ssh_key_name
}

data "hcloud_floating_ip" "main" {
  ip_address = var.server_ip
}

resource "hcloud_server" "chatbot" {
  name        = var.server_name
  server_type = var.server_type
  location    = var.location
  image       = var.image

  ssh_keys = [data.hcloud_ssh_key.default.id]

  labels = {
    purpose = "chatbot"
    env     = "production"
    domain  = var.server_domain
  }

  user_data = <<-EOF
    #cloud-config
    package_update: true
    package_upgrade: true
    packages:
      - docker.io
      - docker-compose
      - git
      - curl
    runcmd:
      - systemctl enable docker
      - systemctl start docker
      - usermod -aG docker root
  EOF
}

resource "hcloud_floating_ip_assignment" "main" {
  floating_ip_id = data.hcloud_floating_ip.main.id
  server_id      = hcloud_server.chatbot.id
}

resource "hcloud_firewall" "chatbot" {
  name = "chatbot-firewall"

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "22"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "80"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "443"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}

resource "hcloud_firewall_attachment" "chatbot" {
  firewall_id = hcloud_firewall.chatbot.id
  server_ids  = [hcloud_server.chatbot.id]
}
