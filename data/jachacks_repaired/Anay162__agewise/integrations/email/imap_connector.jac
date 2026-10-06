"""IMAP email connector — monitors patient/child email for incoming documents.

Uses Python's imaplib to connect to a Gmail or other IMAP account,
fetches unread emails with attachments, extracts text content.
"""

import from os { environ }
import from imaplib { IMAP4_SSL }
import from email { message_from_bytes }
import from email.header { decode_header }

"""Fetch unread emails and return list of dicts with subject, body, attachments_text."""
def fetch_new_emails(
    host: str = "",
    port: int = 993,
    username: str = "",
    password: str = "",
    folder: str = "INBOX",
    max_emails: int = 20
) -> list[dict] {
    h = host or environ.get("IMAP_HOST", "imap.gmail.com");
    p = port or int(environ.get("IMAP_PORT", "993"));
    u = username or environ.get("IMAP_USER", "");
    pw = password or environ.get("IMAP_PASSWORD", "");

    if u == "" or pw == "" {
        print("[IMAPConnector] IMAP credentials not configured, skipping email fetch");
        return [];
    }

    try {
        mail: any = IMAP4_SSL(h, p);
        mail.login(u, pw);
        mail.select(folder);

        # Search for unread messages
        (status, data) = mail.search(None, "UNSEEN");
        if status != "OK" {
            return [];
        }

        email_ids = data[0].split();
        results = [];

        for eid in email_ids[-max_emails:] {
            (status, msg_data) = mail.fetch(eid, "(RFC822)");
            if status != "OK" {
                continue;
            }

            msg: any = message_from_bytes(msg_data[0][1]);

            # Decode subject
            subject_raw = msg.get("Subject", "");
            decoded = decode_header(subject_raw);
            subject = "";
            for (part, enc) in decoded {
                if isinstance(part, bytes) {
                    subject += part.decode(enc or "utf-8", errors="replace");
                } else {
                    subject += str(part);
                }
            }

            sender = msg.get("From", "");
            body = "";

            # Extract body
            if msg.is_multipart() {
                for part in msg.walk() {
                    if part.get_content_type() == "text/plain" {
                        try {
                            body += part.get_payload(decode=True).decode("utf-8", errors="replace");
                        } except Exception { }
                    }
                }
            } else {
                try {
                    body = msg.get_payload(decode=True).decode("utf-8", errors="replace");
                } except Exception { }
            }

            results.append({
                "subject": subject,
                "sender": sender,
                "body": body,
                "attachments_text": "",
                "email_id": eid.decode()
            });

            # Mark as read
            mail.store(eid, "+FLAGS", "\\Seen");
        }

        mail.logout();
        return results;
    } except Exception as e {
        print(f"[IMAPConnector] Error fetching emails: {e}");
        return [];
    }
}
