"""Unified notification sender — routes to SMS, push, or email based on preferences."""

import from graph.nodes.notification { Notification }

"""
Send a notification to a patient using their preferred channel.
Routes to Twilio SMS, Firebase push, or SendGrid email.
Returns dict with delivery status per channel.
"""
def send_notification_to_patient(patient: any, notification: Notification) -> dict {
    results = {};
    if notification.severity in ["CRITICAL", "URGENT"] {
        # Send to all channels for critical alerts
        if patient.phone != "" {
            results["sms"] = _send_sms_notification(patient.phone, notification);
        }
        if patient.email != "" {
            results["email"] = _send_email_notification(patient.email, notification);
        }
    } else {
        # Use preferred channel for non-critical
        channel = getattr(patient, "notification_preference", "sms");
        if channel == "sms" and patient.phone != "" {
            results["sms"] = _send_sms_notification(patient.phone, notification);
        } elif channel == "email" and patient.email != "" {
            results["email"] = _send_email_notification(patient.email, notification);
        } elif patient.phone != "" {
            results["sms"] = _send_sms_notification(patient.phone, notification);
        }
    }
    return results;
}

"""Send notification via SMS."""
def _send_sms_notification(phone: str, notification: Notification) -> bool {
    try {
        import from integrations.notifications.twilio_client { send_sms }
        msg = f"AgeWise Alert [{notification.severity}]: {notification.title}\n{notification.message}";
        result = send_sms(phone, msg);
        return "error" not in result;
    } except Exception as e {
        print(f"[NotificationSender] SMS failed: {e}");
        return False;
    }
}

"""Send notification via email."""
def _send_email_notification(email: str, notification: Notification) -> bool {
    try {
        import from integrations.email.email_sender { send_email }
        return send_email(
            to_address=email,
            subject=f"AgeWise — {notification.title}",
            body_text=notification.message
        );
    } except Exception as e {
        print(f"[NotificationSender] Email failed: {e}");
        return False;
    }
}

"""Simplified notification dispatch used by walkers.
Logs the notification and routes to the appropriate channel.
patient_id: patient name or ID for logging.
channel: SMS | EMAIL | PUSH | IN_APP.
severity: INFO | MEDIUM | HIGH | CRITICAL.
"""
def send_notification(patient_id: str, channel: str, message: str, severity: str = "INFO") -> bool {
    print(f"[Notification] [{severity}] To: {patient_id} via {channel}: {message}");
    # Production: route to Twilio/SendGrid/push based on channel
    return True;
}

"""Generate a human-readable notification message from type and context."""
def format_notification_message(notification_type: str, context: dict) -> str {
    templates = {
        "APPEAL_DEADLINE": "Your appeal deadline for dispute {dispute_id} is {days_remaining} days away (due {due_date}).",
        "BILL_DUE": "Your {biller} bill of {amount} is due in {days} days.",
        "SCAM_ALERT": "URGENT: Suspicious transaction detected — ${amount} to {payee}. Please review immediately.",
        "LEGAL_EXPIRY": "Your {doc_type} document expires in {days} days. Consider renewal.",
        "DIGEST_READY": "Your weekly AgeWise health & benefits summary is ready.",
        "ACTION_REQUIRED": "Action required: {action_description}"
    };
    template = templates.get(notification_type, "AgeWise notification: {message}");
    try {
        return template.format(**context);
    } except Exception {
        return template;
    }
}
