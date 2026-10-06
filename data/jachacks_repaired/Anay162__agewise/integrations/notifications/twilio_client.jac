"""Twilio SMS/voice client for patient and caregiver notifications."""

import from os { environ }

glob TWILIO_FROM_NUMBER: str = "";

"""
Send an SMS via Twilio.
Returns Twilio message SID dict or error dict.
"""
def send_sms(to_number: str, message: str) -> dict {
    try {
        import from twilio.rest { Client }
        account_sid = environ.get("TWILIO_ACCOUNT_SID", "");
        auth_token = environ.get("TWILIO_AUTH_TOKEN", "");
        from_number = environ.get("TWILIO_FROM_NUMBER", "");
        if account_sid == "" or auth_token == "" {
            print("[Twilio] Missing credentials — SMS not sent");
            return {"error": "Missing Twilio credentials"};
        }
        client = Client(account_sid, auth_token);
        msg = client.messages.create(
            body=message,
            from_=from_number,
            to=to_number
        );
        print(f"[Twilio] SMS sent: {msg.sid}");
        return {"sid": msg.sid, "status": msg.status};
    } except Exception as e {
        print(f"[Twilio] SMS failed to {to_number}: {e}");
        return {"error": str(e)};
    }
}

"""Send the same SMS to multiple recipients."""
def send_sms_batch(recipients: list[str], message: str) -> list[dict] {
    results = [];
    for number in recipients {
        results.append(send_sms(number, message));
    }
    return results;
}

"""
Make an outbound Twilio voice call to read an alert message.
twiml_message: plain text (wrapped in <Say> TwiML).
"""
def send_voice_alert(to_number: str, twiml_message: str) -> dict {
    try {
        import from twilio.rest { Client }
        import from twilio.twiml.voice_response { VoiceResponse }
        account_sid = environ.get("TWILIO_ACCOUNT_SID", "");
        auth_token = environ.get("TWILIO_AUTH_TOKEN", "");
        from_number = environ.get("TWILIO_FROM_NUMBER", "");
        client = Client(account_sid, auth_token);
        response = VoiceResponse();
        response.say(twiml_message, voice="Polly.Joanna");
        call = client.calls.create(
            twiml=str(response),
            from_=from_number,
            to=to_number
        );
        return {"call_sid": call.sid, "status": call.status};
    } except Exception as e {
        print(f"[Twilio] Voice alert failed to {to_number}: {e}");
        return {"error": str(e)};
    }
}
