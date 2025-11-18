#!/bin/bash
set -euo pipefail

# Chatbot Server Initial Setup Script
# Run this on the CX53 VM after Terraform provisioning
# Subsequent deployments are handled by GitHub Actions

echo "=== Chatbot Server Setup ==="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# Variables
APP_DIR="/opt/chatbot"
REPO_URL="${REPO_URL:-}"

# Wait for cloud-init to complete
echo "Waiting for cloud-init to complete..."
cloud-init status --wait || true

# Verify Docker is installed
if ! command -v docker &> /dev/null; then
  echo "Docker not found. Installing..."
  apt-get update
  apt-get install -y docker.io docker-compose
  systemctl enable docker
  systemctl start docker
fi

# Create application directory
echo "Creating application directory..."
mkdir -p "$APP_DIR"
cd "$APP_DIR"

# Clone repository if URL provided
if [ -n "$REPO_URL" ]; then
  if [ -d ".git" ]; then
    echo "Repository already exists, pulling latest..."
    git pull origin main
  else
    echo "Cloning repository..."
    git clone "$REPO_URL" .
  fi
else
  echo "Error: REPO_URL is required"
  echo "Usage: REPO_URL=https://github.com/user/repo.git ./setup.sh"
  exit 1
fi

# Check if .env exists (created by GitHub Actions)
if [ ! -f "docker/.env" ]; then
  echo ""
  echo "Warning: docker/.env not found"
  echo "GitHub Actions will create this file during deployment."
  echo "For manual setup, copy docker/.env.example to docker/.env and update values."
fi

# Start Ollama and pull model
echo "Starting Ollama and pulling model..."
cd docker
docker-compose up -d ollama

echo "Waiting for Ollama to be ready..."
sleep 15

MODEL="${OLLAMA_MODEL:-llama3.1:8b}"
echo "Pulling model: $MODEL"
docker exec ollama ollama pull "$MODEL"

# Start all services (if .env exists)
if [ -f ".env" ]; then
  echo "Starting all services..."
  docker-compose up -d
else
  echo "Skipping other services - .env not found"
  echo "Run 'docker-compose up -d' after GitHub Actions creates .env"
fi

echo ""
echo "=== Initial Setup Complete ==="
echo ""
echo "Next steps:"
echo "  1. Push this repo to GitHub"
echo "  2. Run: ./scripts/upload-secrets.sh"
echo "  3. Add SSH_PRIVATE_KEY secret for deployment"
echo "  4. Trigger GitHub Actions workflow"
echo ""
echo "Server IP: $(curl -s ifconfig.me)"
