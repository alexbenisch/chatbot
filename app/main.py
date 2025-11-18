from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBasic, HTTPBasicCredentials
from pydantic import BaseModel
from pydantic_settings import BaseSettings
import httpx
import asyncpg
import secrets
from contextlib import asynccontextmanager


class Settings(BaseSettings):
    database_url: str = "postgresql://chatbot:password@localhost:5432/chatbot_db"
    ollama_host: str = "http://localhost:11434"
    ollama_model: str = "llama3.1:8b"
    secret_key: str = "changeme"
    auth_username: str = "chatbot"
    auth_password: str = "changeme"

    class Config:
        env_file = ".env"


settings = Settings()

# Security
security = HTTPBasic()


def verify_credentials(credentials: HTTPBasicCredentials = Depends(security)) -> str:
    """Verify Basic Auth credentials"""
    correct_username = secrets.compare_digest(
        credentials.username.encode("utf8"),
        settings.auth_username.encode("utf8")
    )
    correct_password = secrets.compare_digest(
        credentials.password.encode("utf8"),
        settings.auth_password.encode("utf8")
    )

    if not (correct_username and correct_password):
        raise HTTPException(
            status_code=401,
            detail="Invalid credentials",
            headers={"WWW-Authenticate": "Basic"},
        )

    return credentials.username

# Database pool
db_pool = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    global db_pool
    try:
        db_pool = await asyncpg.create_pool(settings.database_url, min_size=2, max_size=10)

        # Create tables if not exist
        async with db_pool.acquire() as conn:
            await conn.execute("""
                CREATE TABLE IF NOT EXISTS conversations (
                    id SERIAL PRIMARY KEY,
                    created_at TIMESTAMP DEFAULT NOW(),
                    user_message TEXT NOT NULL,
                    assistant_message TEXT NOT NULL
                )
            """)
            await conn.execute("""
                CREATE TABLE IF NOT EXISTS faqs (
                    id SERIAL PRIMARY KEY,
                    question TEXT NOT NULL,
                    answer TEXT NOT NULL
                )
            """)
        print("Database connected and tables created")
    except Exception as e:
        print(f"Database connection failed: {e}")
        db_pool = None

    yield

    # Shutdown
    if db_pool:
        await db_pool.close()


app = FastAPI(
    title="Chatbot API",
    description="Local LLM Chatbot with Ollama",
    version="1.0.0",
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class ChatRequest(BaseModel):
    message: str
    system_prompt: str | None = "You are a helpful assistant."


class ChatResponse(BaseModel):
    response: str
    model: str


class HealthResponse(BaseModel):
    status: str
    database: str
    ollama: str


@app.get("/health", response_model=HealthResponse)
async def health_check():
    """Check health of all services"""
    db_status = "unhealthy"
    ollama_status = "unhealthy"

    # Check database
    if db_pool:
        try:
            async with db_pool.acquire() as conn:
                await conn.execute("SELECT 1")
            db_status = "healthy"
        except Exception:
            pass

    # Check Ollama
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{settings.ollama_host}/api/tags", timeout=5.0)
            if response.status_code == 200:
                ollama_status = "healthy"
    except Exception:
        pass

    overall = "healthy" if db_status == "healthy" and ollama_status == "healthy" else "degraded"

    return HealthResponse(
        status=overall,
        database=db_status,
        ollama=ollama_status
    )


@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest, username: str = Depends(verify_credentials)):
    """Send a message to the chatbot"""

    # Call Ollama API
    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{settings.ollama_host}/api/generate",
                json={
                    "model": settings.ollama_model,
                    "prompt": request.message,
                    "system": request.system_prompt,
                    "stream": False
                },
                timeout=120.0
            )

            if response.status_code != 200:
                raise HTTPException(status_code=502, detail="Ollama request failed")

            result = response.json()
            assistant_message = result.get("response", "")

    except httpx.TimeoutException:
        raise HTTPException(status_code=504, detail="Ollama timeout")
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Ollama error: {str(e)}")

    # Store conversation in database
    if db_pool:
        try:
            async with db_pool.acquire() as conn:
                await conn.execute(
                    "INSERT INTO conversations (user_message, assistant_message) VALUES ($1, $2)",
                    request.message,
                    assistant_message
                )
        except Exception as e:
            print(f"Failed to store conversation: {e}")

    return ChatResponse(
        response=assistant_message,
        model=settings.ollama_model
    )


@app.get("/conversations")
async def get_conversations(limit: int = 10, username: str = Depends(verify_credentials)):
    """Get recent conversations"""
    if not db_pool:
        raise HTTPException(status_code=503, detail="Database unavailable")

    async with db_pool.acquire() as conn:
        rows = await conn.fetch(
            "SELECT id, created_at, user_message, assistant_message FROM conversations ORDER BY created_at DESC LIMIT $1",
            limit
        )
        return [dict(row) for row in rows]


@app.get("/")
async def root():
    return {
        "message": "Chatbot API",
        "docs": "/docs",
        "health": "/health"
    }
