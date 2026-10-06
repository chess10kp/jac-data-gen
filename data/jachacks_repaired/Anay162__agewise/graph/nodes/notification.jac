"""Notification node — an alert sent to the adult child or patient.

All system alerts flow through notification nodes so they can be
tracked, acknowledged, and audited.
"""

node Notification {
    has notification_id: str = "",
        notification_type: str = "",
        # DISPUTE_FOUND | APPEAL_DEADLINE | LEGAL_EXPIRY | SCAM_ALERT |
        # CLAIM_PROCESSED | WEEKLY_DIGEST | CARE_GAP | REFILL_OVERDUE |
        # BILL_OVERDUE | BENEFITS_FOUND | ACTION_REQUIRED
        severity: str = "INFO",         # INFO | WARNING | URGENT | CRITICAL
        title: str = "",
        message: str = "",
        channel: str = "email",         # email | sms | push | in_app
        recipient_type: str = "adult_child",
        delivered_at: str = "",
        read_at: str = "",
        action_url: str = "",           # deep link to relevant page
        reference_id: str = "",         # related claim/rx/bill id
        metadata: str = "",             # JSON string with extra context
        created_at: str = "";
}
