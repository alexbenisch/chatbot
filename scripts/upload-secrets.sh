#!/bin/bash
set -euo pipefail

# Upload secrets from .env to GitHub repository secrets
# Usage: ./scripts/upload-secrets.sh

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$REPO_ROOT/.env"

# Check if .env exists
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: $ENV_FILE not found"
    exit 1
fi

# Check if gh is installed
if ! command -v gh &> /dev/null; then
    echo "Error: gh CLI is not installed"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo "Error: Not authenticated with GitHub"
    echo "Run: gh auth login"
    exit 1
fi

echo "Uploading secrets to GitHub repository..."

# Read .env and upload each variable
while IFS= read -r line || [ -n "$line" ]; do
    # Skip empty lines and comments
    [[ -z "$line" || "$line" =~ ^# ]] && continue

    # Extract key and value
    key="${line%%=*}"
    value="${line#*=}"

    # Remove quotes from value
    value="${value%\"}"
    value="${value#\"}"

    echo "  Setting $key..."
    echo "$value" | gh secret set "$key"
done < "$ENV_FILE"

echo ""
echo "Secrets uploaded successfully!"
echo "View with: gh secret list"
