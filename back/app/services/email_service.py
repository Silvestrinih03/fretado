import smtplib
from email.message import EmailMessage
from html import escape

from app.core.config import settings


class EmailConfigurationError(Exception):
    pass


class EmailSendError(Exception):
    pass


def send_password_reset_email(email: str, reset_link: str) -> None:
    sender = settings.EMAIL_FROM or settings.EMAIL_USER
    _validate_email_settings(sender)
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
        raise EmailSendError("Unable to connect to email server.") from exc


def _validate_email_settings(sender: str) -> None:
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


def _login_and_send(smtp: smtplib.SMTP, message: EmailMessage) -> None:
    smtp.login(settings.EMAIL_USER, settings.EMAIL_PASSWORD)
    smtp.send_message(message)
