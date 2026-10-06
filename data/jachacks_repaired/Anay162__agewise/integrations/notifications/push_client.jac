"""Push notification client for mobile app alerts (Firebase FCM)."""

import from os { environ }

"""
Send a push notification via Firebase Cloud Messaging.
Returns FCM message ID or error dict.
"""
def send_push_notification(device_token: str, title: str, body: str, data: dict = {}) -> dict {
    try {
        import from firebase_admin { messaging, initialize_app, credentials }
        cred_path = environ.get("FIREBASE_CREDENTIALS_PATH", "");
        if cred_path != "" {
            cred = credentials.Certificate(cred_path);
            initialize_app(cred);
        }
        message = messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            data={k: str(v) for (k, v) in data.items()},
            token=device_token
        );
        response = messaging.send(message);
        print(f"[Push] Notification sent: {response}");
        return {"message_id": response};
    } except Exception as e {
        print(f"[Push] Notification failed: {e}");
        return {"error": str(e)};
}

"""Send push notifications to multiple devices."""
def send_push_batch(device_tokens: list[str], title: str, body: str) -> dict {
    try {
        import from firebase_admin { messaging }
        messages = [
            messaging.Message(
                notification=messaging.Notification(title=title, body=body),
                token=token
            )
            for token in device_tokens
        ];
        response = messaging.send_each(messages);
        return {
            "success_count": response.success_count,
            "failure_count": response.failure_count
        };
    } except Exception as e {
        print(f"[Push] Batch notification failed: {e}");
        return {"error": str(e)};
    }
}
}
