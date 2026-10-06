"""Email parser — extracts structured data from raw email messages."""

"""
Parse a raw email message into structured fields.
Returns dict with subject, sender, body_text, attachments, etc.
"""
def parse_email_message(raw_email: bytes) -> dict {
    try {
        import from email { message_from_bytes }
        import from email.header { decode_header }
        msg = message_from_bytes(raw_email);
        # Decode subject
        raw_subject = msg.get("Subject", "");
        subject_parts = decode_header(raw_subject);
        subject = "";
        for (part, enc) in subject_parts {
            if isinstance(part, bytes) {
                subject += part.decode(enc or "utf-8", errors="replace");
            } else {
                subject += part;
            }
        }
        # Extract sender
        sender = msg.get("From", "");
        date_str = msg.get("Date", "");
        # Extract body and attachments
        body_text = "";
        attachments = [];
        if msg.is_multipart() {
            for part in msg.walk() {
                content_type = part.get_content_type();
                content_disp = str(part.get("Content-Disposition", ""));
                if "attachment" in content_disp {
                    filename = part.get_filename() or "attachment";
                    attachments.append({
                        "filename": filename,
                        "content_type": content_type,
                        "data": part.get_payload(decode=True)
                    });
                } elif content_type == "text/plain" and "attachment" not in content_disp {
                    payload: any = part.get_payload(decode=True);
                    if payload {
                        charset = part.get_content_charset() or "utf-8";
                        body_text += payload.decode(charset, errors="replace");
                    }
                }
            }
        } else {
            payload: any = msg.get_payload(decode=True);
            if payload {
                charset = msg.get_content_charset() or "utf-8";
                body_text = payload.decode(charset, errors="replace");
            }
        }
        return {
            "subject": subject,
            "sender": sender,
            "date": date_str,
            "body_text": body_text.strip(),
            "attachments": attachments
        };
    } except Exception as e {
        print(f"[EmailParser] Parse failed: {e}");
        return {"subject": "", "sender": "", "date": "", "body_text": "", "attachments": []};
    }
}

"""Quick heuristic to detect if an email is healthcare/insurance-related."""
def is_healthcare_email(subject: str, body: str) -> bool {
    keywords = [
        "medicare", "medicaid", "explanation of benefits", "eob",
        "claim", "insurance", "provider", "hospital", "prescription",
        "medicare summary notice", "msn", "statement", "remittance"
    ];
    combined = (subject + " " + body).lower();
    return any(kw in combined for kw in keywords);
}
