"""
이메일 발송 (인증 링크 등)
- SENDGRID_API_KEY 있으면 SendGrid 사용
- 없으면 로그만 (개발 시 인증 링크 확인용)
"""
import logging
from typing import Optional

from app.core.config import settings

logger = logging.getLogger(__name__)


def send_verification_email(to_email: str, verify_token: str) -> None:
    """
    인증 링크 이메일 발송.
    FRONTEND_VERIFY_URL이 있으면 링크에 token 쿼리 붙여서 사용.
    """
    base = (settings.FRONTEND_VERIFY_URL or "").strip().rstrip("/")
    link = f"{base}?token={verify_token}" if base else f"(no base URL) token={verify_token}"

    if settings.SENDGRID_API_KEY:
        _send_via_sendgrid(to_email, link)
    else:
        logger.info(
            "[Email] Verification link (not sent, no SENDGRID_API_KEY): to=%s link=%s",
            to_email,
            link,
        )


def _send_via_sendgrid(to_email: str, link: str) -> None:
    try:
        import sendgrid
        from sendgrid.helpers.mail import Mail, Email, To, Content

        from_email = settings.EMAIL_FROM or "noreply@heygeno.com"
        subject = "Verify your email - HeyGeno"
        html = f"""
        <p>Please verify your email by clicking the link below.</p>
        <p><a href="{link}">Verify email</a></p>
        <p>If you didn't create an account, you can ignore this email.</p>
        """
        message = Mail(
            from_email=Email(from_email),
            to_emails=To(to_email),
            subject=subject,
            html_content=Content("text/html", html),
        )
        sg = sendgrid.SendGridAPIClient(api_key=settings.SENDGRID_API_KEY)
        sg.send(message)
        logger.info("[Email] Verification email sent to %s", to_email)
    except Exception as e:
        logger.exception("[Email] SendGrid send failed: %s", e)
        raise
