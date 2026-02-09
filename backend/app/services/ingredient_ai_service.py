"""성분 분석 AI 서비스"""
import json
import logging
from typing import Optional
from app.utils.openai_client import get_openai_client
from app.core.config import settings

logger = logging.getLogger(__name__)

SYSTEM_PROMPT = """너는 반려동물 사료 성분 분석 전문가다.
반드시 JSON만 출력한다.
설명이나 추가 텍스트 없이 순수 JSON만 반환해야 한다."""

USER_PROMPT_TEMPLATE = """아래 사료 원재료 정보를 분석해 JSON으로 구조화해라.

[species]
{species}

[ingredients_text]
{ingredients_text}

[additives_text]
{additives_text}

반환 형식(JSON만, 설명 금지):
{{
  "raw_text": "...",
  "ingredients_ordered": [],
  "first_five": [],
  "animal_proteins": [],
  "plant_proteins": [],
  "grains": [],
  "potential_allergens": [],
  "additives": [],
  "is_grain_free": true,
  "first_ingredient_is_meat": true,
  "protein_source_quality": "low|medium|high",
  "quality_score": 0,
  "notes": "한 줄 요약"
}}"""


async def analyze_ingredients_with_ai(
    ingredients_text: str,
    additives_text: str = "",
    species: Optional[str] = None,
) -> dict:
    """
    OpenAI를 사용하여 성분 텍스트를 분석하고 구조화된 JSON 반환
    
    Args:
        ingredients_text: 원재료 텍스트
        additives_text: 첨가물 텍스트 (선택)
        species: 반려동물 종류 (DOG/CAT, 선택)
    
    Returns:
        구조화된 성분 정보 딕셔너리
    
    Raises:
        ValueError: OpenAI API 호출 실패 또는 JSON 파싱 실패
    """
    if not ingredients_text or not ingredients_text.strip():
        raise ValueError("ingredients_text는 필수입니다.")
    
    try:
        client = get_openai_client()
        
        prompt = USER_PROMPT_TEMPLATE.format(
            ingredients_text=ingredients_text.strip(),
            additives_text=(additives_text or "").strip(),
            species=species or "UNKNOWN"
        )
        
        logger.info(f"OpenAI API 호출 시작 (model: {settings.OPENAI_MODEL})")
        
        response = client.chat.completions.create(
            model=settings.OPENAI_MODEL,
            temperature=settings.OPENAI_TEMPERATURE,
            max_tokens=settings.OPENAI_MAX_TOKENS,
            messages=[
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": prompt},
            ],
        )
        
        content = response.choices[0].message.content.strip()
        logger.info(f"OpenAI 응답 수신 (길이: {len(content)})")
        
        # JSON 추출 (마크다운 코드 블록 제거)
        if content.startswith("```json"):
            content = content[7:]  # ```json 제거
        if content.startswith("```"):
            content = content[3:]  # ``` 제거
        if content.endswith("```"):
            content = content[:-3]  # ``` 제거
        content = content.strip()
        
        try:
            parsed = json.loads(content)
            logger.info("JSON 파싱 성공")
            return parsed
        except json.JSONDecodeError as e:
            logger.error(f"JSON 파싱 실패: {e}\n응답 내용:\n{content}")
            raise ValueError(f"OpenAI 응답이 유효한 JSON이 아닙니다: {str(e)}\n응답 내용:\n{content[:500]}")
            
    except Exception as e:
        logger.error(f"OpenAI API 호출 실패: {str(e)}", exc_info=True)
        if isinstance(e, ValueError):
            raise
        raise ValueError(f"성분 분석 중 오류가 발생했습니다: {str(e)}")
