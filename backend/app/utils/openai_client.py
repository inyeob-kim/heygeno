"""OpenAI 클라이언트 초기화"""
from openai import OpenAI
from app.core.config import settings

# OpenAI 클라이언트 초기화
client = None

def get_openai_client() -> OpenAI:
    """OpenAI 클라이언트 반환 (지연 초기화)"""
    global client
    if client is None:
        if not settings.OPENAI_API_KEY:
            raise ValueError("OPENAI_API_KEY가 설정되지 않았습니다. .env 파일을 확인하세요.")
        client = OpenAI(api_key=settings.OPENAI_API_KEY)
    return client
