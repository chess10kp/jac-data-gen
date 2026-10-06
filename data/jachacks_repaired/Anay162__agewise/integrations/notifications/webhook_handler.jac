"""Webhook handler — processes inbound webhooks from Plaid, Bland.ai, and Twilio."""

import from os { environ }
import from hashlib { sha256 }
import from hmac { new as hmac_new, compare_digest }

"""Verify Plaid webhook signature using JWT verification."""
def verify_plaid_webhook(payload: bytes, plaid_signature: str) -> bool {
    try {
        import from jose { jwt }
        # Plaid uses JWT-signed webhooks; decode and verify
        webhook_key = environ.get("PLAID_WEBHOOK_SECRET", "");
        if webhook_key == "" {
            return False;
        }
        decoded = jwt.decode(plaid_signature, webhook_key, algorithms=["HS256"]);
        return decoded is not None;
    } except Exception {
        return False;
    }
}

"""Verify Bland.ai webhook HMAC-SHA256 signature."""
def verify_bland_webhook(payload: bytes, signature: str) -> bool {
    try {
        secret = environ.get("BLAND_WEBHOOK_SECRET", "").encode();
        if len(secret) == 0 {
            return True;  # Skip verification in dev
        }
        expected = hmac_new(secret, payload, sha256).hexdigest();
        return compare_digest(expected, signature);
    } except Exception {
        return False;
    }
}

"""Verify Twilio webhook signature."""
def verify_twilio_webhook(payload: bytes, signature: str, url: str) -> bool {
    try {
        import from twilio.request_validator { RequestValidator }
        auth_token = environ.get("TWILIO_AUTH_TOKEN", "");
        validator = RequestValidator(auth_token);
        return validator.validate(url, payload, signature);
    } except Exception {
        return False;
    }
}

"""
Parse a Bland.ai call completion webhook event.
Returns structured call result.
"""
def parse_bland_call_event(event: dict) -> dict {
    return {
        "call_id": event.get("call_id", ""),
        "status": event.get("status", ""),
        "duration_seconds": event.get("call_length", 0),
        "transcript": event.get("transcript", ""),
        "recording_url": event.get("recording_url", ""),
        "completed_at": event.get("end_time", ""),
        "outcome": event.get("analysis", {})
    };
}

"""
Parse a Plaid transactions webhook event.
Returns structured transaction sync request.
"""
def parse_plaid_transaction_event(event: dict) -> dict {
    return {
        "webhook_type": event.get("webhook_type", ""),
        "webhook_code": event.get("webhook_code", ""),
        "item_id": event.get("item_id", ""),
        "new_transactions": event.get("new_transactions", 0),
        "removed_transactions": event.get("removed_transactions", [])
    };
}
