import base64
import smtplib
from email.message import EmailMessage
from html import escape

import requests

from app.core.config import settings


class EmailConfigurationError(Exception):
    pass


class EmailSendError(Exception):
    pass


def send_password_reset_email(email: str, reset_link: str) -> None:
    sender = settings.EMAIL_FROM or settings.EMAIL_USER
    message = _build_password_reset_message(email, reset_link, sender)

    if settings.EMAIL_PROVIDER in {"gmail", "gmail_api"}:
        _send_with_gmail_api(message, sender)
        return

    _send_with_smtp(message, sender)


def _build_password_reset_message(
    email: str,
    reset_link: str,
    sender: str,
) -> EmailMessage:
    html_reset_link = escape(reset_link, quote=True)

    message = EmailMessage()
    message["Subject"] = "Recuperacao de senha - Fretado"
    message["From"] = sender
    message["To"] = email
    message.set_content(
        "Recebemos uma solicitacao para redefinir sua senha no Fretado.\n\n"
        f"Acesse o link abaixo para criar uma nova senha:\n{reset_link}\n\n"
        "Este link expira em alguns minutos. Se voce nao solicitou a "
        "recuperacao de senha, ignore este e-mail."
    )
    message.add_alternative(
        f"""
        <html>
          <body style="font-family: Arial, sans-serif; color: #1f2937;">
            <h2 style="color: #10206e;">Recuperacao de senha</h2>
            <p>Recebemos uma solicitacao para redefinir sua senha no Fretado.</p>
            <p>
              <a href="{html_reset_link}" style="background: #10206e; color: #ffffff; padding: 12px 18px; text-decoration: none; border-radius: 6px; display: inline-block;">
                Criar nova senha
              </a>
            </p>
            <p>Este link expira em alguns minutos.</p>
            <p>Se voce nao solicitou a recuperacao de senha, ignore este e-mail.</p>
          </body>
        </html>
        """,
        subtype="html",
    )

    return message


def _send_with_smtp(message: EmailMessage, sender: str) -> None:
    _validate_smtp_settings(sender)

    try:
        if settings.EMAIL_USE_SSL:
            with smtplib.SMTP_SSL(
                settings.EMAIL_HOST,
                settings.EMAIL_PORT,
                timeout=15,
            ) as smtp:
                _login_and_send(smtp, message)
            return

        with smtplib.SMTP(
            settings.EMAIL_HOST,
            settings.EMAIL_PORT,
            timeout=15,
        ) as smtp:
            if settings.EMAIL_USE_TLS:
                smtp.starttls()
            _login_and_send(smtp, message)
    except smtplib.SMTPException as exc:
        raise EmailSendError("Unable to send password reset email.") from exc
    except OSError as exc:
        raise EmailSendError(
            "Unable to connect to SMTP server. Render free web services block "
            "outbound SMTP ports 25, 465, and 587; use EMAIL_PROVIDER=gmail_api "
            "or a paid Render instance."
        ) from exc


def _send_with_gmail_api(message: EmailMessage, sender: str) -> None:
    _validate_gmail_api_settings(sender)

    access_token = _get_gmail_access_token()
    raw_message = base64.urlsafe_b64encode(message.as_bytes()).decode("utf-8")

    try:
        response = requests.post(
            "https://gmail.googleapis.com/gmail/v1/users/me/messages/send",
            headers={
                "Authorization": f"Bearer {access_token}",
                "Content-Type": "application/json",
            },
            json={"raw": raw_message},
            timeout=15,
        )
    except requests.RequestException as exc:
        raise EmailSendError("Unable to connect to Gmail API.") from exc

    if response.status_code >= 400:
        raise EmailSendError(
            f"Gmail API rejected the email request with status {response.status_code}."
        )


def _validate_smtp_settings(sender: str) -> None:
    missing_settings = [
        name
        for name, value in (
            ("EMAIL_HOST", settings.EMAIL_HOST),
            ("EMAIL_USER", settings.EMAIL_USER),
            ("EMAIL_PASSWORD", settings.EMAIL_PASSWORD),
            ("EMAIL_FROM", sender),
        )
        if not value
    ]

    if missing_settings:
        raise EmailConfigurationError(
            "Missing email settings: " + ", ".join(missing_settings)
        )


def _validate_gmail_api_settings(sender: str) -> None:
    missing_settings = [
        name
        for name, value in (
            ("EMAIL_FROM", sender),
            ("GMAIL_CLIENT_ID", settings.GMAIL_CLIENT_ID),
            ("GMAIL_CLIENT_SECRET", settings.GMAIL_CLIENT_SECRET),
            ("GMAIL_REFRESH_TOKEN", settings.GMAIL_REFRESH_TOKEN),
        )
        if not value
    ]

    if missing_settings:
        raise EmailConfigurationError(
            "Missing Gmail API settings: " + ", ".join(missing_settings)
        )


def _get_gmail_access_token() -> str:
    try:
        response = requests.post(
            settings.GMAIL_TOKEN_URL,
            data={
                "client_id": settings.GMAIL_CLIENT_ID,
                "client_secret": settings.GMAIL_CLIENT_SECRET,
                "refresh_token": settings.GMAIL_REFRESH_TOKEN,
                "grant_type": "refresh_token",
            },
            timeout=15,
        )
    except requests.RequestException as exc:
        raise EmailSendError("Unable to connect to Google OAuth API.") from exc

    if response.status_code >= 400:
        raise EmailSendError(
            f"Google OAuth rejected the token request with status {response.status_code}."
        )

    access_token = response.json().get("access_token")
    if not access_token:
        raise EmailSendError("Google OAuth response did not include an access token.")

    return access_token


def _login_and_send(smtp: smtplib.SMTP, message: EmailMessage) -> None:
    smtp.login(settings.EMAIL_USER, settings.EMAIL_PASSWORD)
    smtp.send_message(message)
