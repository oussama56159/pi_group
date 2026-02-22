"""SMTP email sending utilities.

Kept dependency-free (stdlib only) so Docker images don't need extra packages.
"""

from __future__ import annotations

from email.message import EmailMessage
from functools import partial
import smtplib

import anyio

from backend.shared.config import BaseServiceSettings


class EmailSendError(RuntimeError):
    pass


def _send_smtp_sync(
    settings: BaseServiceSettings,
    *,
    to_email: str,
    subject: str,
    body: str,
    reply_to: str | None = None,
) -> None:
    if not settings.SMTP_HOST:
        raise EmailSendError("SMTP is not configured (SMTP_HOST is missing).")

    from_email = settings.SMTP_FROM_EMAIL or settings.SMTP_USERNAME or settings.SUPPORT_EMAIL
    if not from_email:
        raise EmailSendError("SMTP_FROM_EMAIL is not configured.")

    msg = EmailMessage()
    msg["From"] = from_email
    msg["To"] = to_email
    msg["Subject"] = subject
    if reply_to:
        msg["Reply-To"] = reply_to
    msg.set_content(body)

    try:
        if settings.SMTP_USE_SSL:
            server: smtplib.SMTP = smtplib.SMTP_SSL(settings.SMTP_HOST, settings.SMTP_PORT, timeout=15)
        else:
            server = smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT, timeout=15)

        with server:
            if settings.SMTP_USE_STARTTLS and not settings.SMTP_USE_SSL:
                server.starttls()

            if settings.SMTP_USERNAME and settings.SMTP_PASSWORD:
                server.login(settings.SMTP_USERNAME, settings.SMTP_PASSWORD)

            server.send_message(msg)
    except Exception as e:
        raise EmailSendError(str(e)) from e


async def send_email_smtp(
    settings: BaseServiceSettings,
    *,
    to_email: str,
    subject: str,
    body: str,
    reply_to: str | None = None,
) -> None:
    fn = partial(
        _send_smtp_sync,
        settings,
        to_email=to_email,
        subject=subject,
        body=body,
        reply_to=reply_to,
    )
    await anyio.to_thread.run_sync(fn)
