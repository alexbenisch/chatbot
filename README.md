# Chatbot

A self-hosted chatbot powered by Ollama and served via FastAPI, with automatic HTTPS through Caddy.

## Architecture

```
┌─────────────────────────────────────────────────┐
│              Docker Compose Stack               │
│                                                 │
│  ┌─────────┐    ┌─────────┐    ┌─────────────┐  │
│  │  Caddy  │───▶│ FastAPI │───▶│   Ollama    │  │
│  │ :80/:443│    │  :8000  │    │   :11434    │  │
│  └────┬────┘    └────┬────┘    └─────────────┘  │
│       │              │                          │
│       │         ┌────▼────┐                     │
│  ┌────▼────┐    │Postgres │                     │
│  │ Chat-UI │    │  :5432  │                     │
│  │  :3000  │    └─────────┘                     │
│  └─────────┘                                    │
└─────────────────────────────────────────────────┘
```

## Components

| Service | Description |
|---------|-------------|
| **Ollama** | Local LLM inference engine running llama3.1:8b |
| **PostgreSQL** | Stores conversation history |
| **FastAPI** | REST API for chat interactions |
| **Caddy** | Reverse proxy with automatic HTTPS via Let's Encrypt |
| **Chat-UI** | Web interface for the chatbot |

## Repository Structure

```
chatbot/
├── app/                          # FastAPI application
│   ├── main.py                   # API endpoints and logic
│   ├── Dockerfile
│   └── pyproject.toml
├── chat-ui/                      # Web interface
│   ├── public/
│   │   ├── index.html
│   │   ├── css/style.css
│   │   └── js/chat.js
│   ├── nginx.conf
│   └── Dockerfile
├── docker/                       # Docker configuration
│   ├── docker-compose.yml
│   └── Caddyfile
├── .github/workflows/            # CI/CD
│   └── build-push.yml
└── README.md
```

## API Endpoints

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/` | GET | No | API information |
| `/health` | GET | No | Health status of all services |
| `/chat` | POST | Yes | Send message to chatbot |
| `/conversations` | GET | Yes | Retrieve conversation history |

### Chat Request

```bash
curl -u "username:password" \
  -X POST https://chatbot.k8s-demo.de/chat \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Hello!",
    "system_prompt": "You are a helpful assistant."
  }'
```

### Response

```json
{
  "response": "Hello! How can I help you today?",
  "model": "llama3.1:8b"
}
```

## Deployment

### Prerequisites

- Server with Docker and Docker Compose installed
- Domain names pointing to your server:
  - `chatbot.k8s-demo.de` - API
  - `chat.k8s-demo.de` - Web UI
- GitHub repository secrets configured

### GitHub Secrets

Configure these secrets in your repository settings:

| Secret | Description |
|--------|-------------|
| `SERVER_IP` | Server IP address |
| `SSH_PRIVATE_KEY` | SSH key for server access |
| `POSTGRES_USER` | PostgreSQL username |
| `POSTGRES_PASSWORD` | PostgreSQL password |
| `POSTGRES_DB` | PostgreSQL database name |
| `OLLAMA_MODEL` | LLM model (e.g., `llama3.1:8b`) |
| `SECRET_KEY` | Application secret key |
| `AUTH_USERNAME` | API Basic Auth username |
| `AUTH_PASSWORD` | API Basic Auth password |

### Automatic Deployment (GitOps)

Push to the `main` branch triggers automatic deployment:

1. GitHub Actions builds the Docker image
2. Pushes to GitHub Container Registry
3. SSHs to server and pulls latest code
4. Recreates containers with `docker-compose up -d`

```bash
git add .
git commit -m "Your changes"
git push origin main
```

### Manual Deployment

SSH to your server and run:

```bash
cd /opt/chatbot
git pull origin main

# Create .env file
cat > docker/.env << EOF
POSTGRES_USER=chatbot
POSTGRES_PASSWORD=your-secure-password
POSTGRES_DB=chatbot_db
OLLAMA_MODEL=llama3.1:8b
SECRET_KEY=your-secret-key
AUTH_USERNAME=chatbot
AUTH_PASSWORD=your-auth-password
EOF

# Start services
cd docker
docker-compose down
docker-compose up -d
```

### First-Time Setup

After initial deployment, pull the Ollama model:

```bash
docker exec -it ollama ollama pull llama3.1:8b
```

## URLs

- **API**: https://chatbot.k8s-demo.de
- **API Docs**: https://chatbot.k8s-demo.de/docs
- **Chat UI**: https://chat.k8s-demo.de
- **Health Check**: https://chatbot.k8s-demo.de/health

## Local Development

1. Clone the repository:
   ```bash
   git clone https://github.com/alexbenisch/chatbot.git
   cd chatbot
   ```

2. Create environment file:
   ```bash
   cp docker/.env.example docker/.env
   # Edit docker/.env with your values
   ```

3. Start services:
   ```bash
   cd docker
   docker-compose up -d
   ```

4. Pull the LLM model:
   ```bash
   docker exec -it ollama ollama pull llama3.1:8b
   ```

5. Access the API at `http://localhost:8000`

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `POSTGRES_USER` | Database user | `chatbot` |
| `POSTGRES_PASSWORD` | Database password | - |
| `POSTGRES_DB` | Database name | `chatbot_db` |
| `OLLAMA_HOST` | Ollama API URL | `http://ollama:11434` |
| `OLLAMA_MODEL` | LLM model to use | `llama3.1:8b` |
| `SECRET_KEY` | App secret key | - |
| `AUTH_USERNAME` | Basic Auth user | - |
| `AUTH_PASSWORD` | Basic Auth password | - |

### Changing the LLM Model

1. Update `OLLAMA_MODEL` in your `.env` or GitHub secrets
2. Pull the new model:
   ```bash
   docker exec -it ollama ollama pull <model-name>
   ```

Available models: https://ollama.com/library

## Monitoring

### Check Service Health

```bash
curl https://chatbot.k8s-demo.de/health
```

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f fastapi
docker-compose logs -f ollama
```

### Container Status

```bash
docker-compose ps
```

## Troubleshooting

### Ollama Not Ready

If the health check shows Ollama as unhealthy, the model may still be loading:

```bash
docker logs ollama
docker exec -it ollama ollama list
```

### Database Connection Issues

Check PostgreSQL is running and healthy:

```bash
docker exec -it postgres pg_isready
```

### API Returns 401

Verify your Basic Auth credentials match the environment variables.

### Chat UI Shows "Offline"

The UI checks `/api/health`. Ensure FastAPI is running:

```bash
docker logs fastapi
```

## License

MIT
