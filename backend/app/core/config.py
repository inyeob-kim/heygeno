import os

from pydantic_settings import BaseSettings
from typing import Optional

# backend/.env 를 실행 위치와 관계없이 로드 (config.py 기준 backend 루트)
_BACKEND_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
_ENV_FILE = os.path.join(_BACKEND_ROOT, ".env")


class Settings(BaseSettings):
    # Environment
    ENVIRONMENT: str = "development"
    
    # Database
    DATABASE_URL: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/petfood"
    
    # Redis
    REDIS_URL: str = "redis://localhost:6379/0"
    
    # Security
    SECRET_KEY: str = "your-secret-key-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # API Keys
    AFFILIATE_API_KEY: Optional[str] = None
    
    # Coupang API Keys
    COUPANG_ACCESS_KEY: Optional[str] = None
    COUPANG_SECRET_KEY: Optional[str] = None
    
    # OpenAI
    OPENAI_API_KEY: Optional[str] = None
    OPENAI_MODEL: str = "gpt-4o-mini"
    OPENAI_TEMPERATURE: float = 0.3
    OPENAI_MAX_TOKENS: int = 1200
    
    # RAG Vector Store 설정
    VECTOR_STORE_TYPE: str = "local"  # local, pinecone, weaviate
    VECTOR_STORE_PATH: str = "./data/vector_store"
    
    # Pinecone 설정 (선택사항)
    PINECONE_API_KEY: Optional[str] = None
    PINECONE_ENVIRONMENT: Optional[str] = None
    PINECONE_INDEX_NAME: Optional[str] = None
    
    # Weaviate 설정 (선택사항)
    WEAVIATE_URL: Optional[str] = None
    WEAVIATE_API_KEY: Optional[str] = None
    
    # Worker Settings
    PRICE_COLLECTOR_INTERVAL_MINUTES: int = 60

    # Billing (IAP)
    IOS_PRODUCT_ID: Optional[str] = None
    ANDROID_PRODUCT_ID: Optional[str] = None

    # Auth (OAuth client IDs for id_token verification)
    GOOGLE_CLIENT_ID: Optional[str] = None

    # Firebase (for firebase-login; path to service account JSON)
    FIREBASE_CREDENTIALS_PATH: Optional[str] = None

    class Config:
        env_file = _ENV_FILE
        case_sensitive = True


settings = Settings()

