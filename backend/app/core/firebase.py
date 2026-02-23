"""Firebase Admin SDK 초기화 및 id_token 검증."""
from __future__ import annotations

import os
from typing import Any

_firebase_app = None


def get_firebase_app():
    """Firebase Admin 앱 인스턴스 반환. 미초기화 시 None."""
    global _firebase_app
    return _firebase_app


def _get_backend_root() -> str:
    """backend/app/core/firebase.py → backend/ 절대 경로."""
    return os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def _resolve_credentials_path(path: str) -> str:
    """상대 경로면 backend 루트 기준으로 절대 경로 반환."""
    if os.path.isabs(path) and os.path.isfile(path):
        return path
    root = _get_backend_root()
    resolved = os.path.normpath(os.path.join(root, path))
    return resolved if os.path.isfile(resolved) else path


def initialize_firebase(credentials_path: str | None = None) -> bool:
    """
    Firebase Admin SDK 초기화.
    credentials_path가 없거나 파일이 없으면 False 반환.
    상대 경로는 backend 루트 기준. env 없어도 backend/config/firebase-service-account.json 자동 시도.
    """
    global _firebase_app
    if _firebase_app is not None:
        return True
    root = _get_backend_root()
    # 1) 인자 또는 환경변수 2) 기본 경로 backend/config/firebase-service-account.json
    path = credentials_path or os.environ.get("FIREBASE_CREDENTIALS_PATH")
    if path:
        path = _resolve_credentials_path(path)
    if not path or not os.path.isfile(path):
        default = os.path.join(root, "config", "firebase-service-account.json")
        if os.path.isfile(default):
            path = default
    if not path or not os.path.isfile(path):
        return False
    try:
        import firebase_admin
        from firebase_admin import credentials
        cred = credentials.Certificate(path)
        _firebase_app = firebase_admin.initialize_app(cred)
        return True
    except Exception:
        return False


def verify_firebase_token(id_token: str) -> dict[str, Any] | None:
    """
    Firebase id_token 검증 후 디코딩된 클레임 반환.
    uid, email, name 등 포함. 실패 시 None.
    """
    app = get_firebase_app()
    if app is None:
        return None
    try:
        from firebase_admin import auth
        decoded = auth.verify_id_token(id_token, app=app)
        return decoded if isinstance(decoded, dict) else None
    except Exception:
        return None
