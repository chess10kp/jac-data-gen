"""Email sender — sends transactional emails via SendGrid or SMTP."""

import from os { environ }

"""
Send a transactional email.
Uses SendGrid if SENDGRID_API_KEY is set, otherwise falls back to SMTP.
Returns True on success.
"""
def send_email(to_address: str, subject: str, body_text: str, body_html: str = "") -> bool {
    sendgrid_key = environ.get("SENDGRID_API_KEY", "");
    if sendgrid_key != "" {
        return _send_via_sendgrid(to_address, subject, body_text, body_html, sendgrid_key);
    }
    return _send_via_smtp(to_address, subject, body_text);
}

"""Send email via SendGrid API."""
def _send_via_sendgrid(to_address: str, subject: str, body_text: str, body_html: str, api_key: str) -> bool {
    try {
        import from sendgrid { SendGridAPIClient }
        import from sendgrid.helpers.mail { Mail }
        from_email = environ.get("EMAIL_FROM", "noreply@agewise.ai");
        message = Mail(
            from_email=from_email,
            to_emails=to_address,
            subject=subject,
            plain_text_content=body_text,
            html_content=body_html if body_html != "" else f"<pre>{body_text}</pre>"
        );
        sg = SendGridAPIClient(api_key);
        response = sg.send(message);
        success = response.status_code in [200, 202];
        print(f"[Email] Sent via SendGrid to {to_address}: status {response.status_code}");
        return success;
    } except Exception as e {
        print(f"[Email] SendGrid failed: {e}");
        return False;
    }
}

"""Send email via SMTP."""
def _send_via_smtp(to_address: str, subject: str, body_text: str) -> bool {
    try {
        import from smtplib { SMTP }
        import from email.mime.text { MIMEText }
        import from email.mime.multipart { MIMEMultipart }
        smtp_host = environ.get("SMTP_HOST", "localhost");
        smtp_port = int(environ.get("SMTP_PORT", "587"));
        smtp_user = environ.get("SMTP_USER", "");
        smtp_pass = environ.get("SMTP_PASS", "");
        from_email = environ.get("EMAIL_FROM", "noreply@agewise.ai");
        msg = MIMEMultipart();
        msg["From"] = from_email;
        msg["To"] = to_address;
        msg["Subject"] = subject;
        msg.attach(MIMEText(body_text, "plain"));
        with SMTP(smtp_host, smtp_port) as server {
            if smtp_user != "" {
                server.starttls();
                server.login(smtp_user, smtp_pass);
            }
            server.sendmail(from_email, to_address, msg.as_string());
        }
        print(f"[Email] Sent via SMTP to {to_address}");
        return True;
    } except Exception as e {
        print(f"[Email] SMTP failed: {e}");
        return False;
    }
}

"""Send an appeal letter draft by email."""
def send_appeal_letter_email(to_address: str, dispute_id: str, letter_content: str) -> bool {
    subject = f"AgeWise — Appeal Letter Draft (Dispute {dispute_id})";
    body = f"Please review the attached appeal letter draft.\n\n{letter_content}\n\nNote: This draft requires attorney review before submission.";
    return send_email(to_address, subject, body);
}
