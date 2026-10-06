"""Notification configuration — channels, templates, and scheduling."""

import from os { environ }

# Default notification channels by severity
glob NOTIFICATION_ROUTING: dict = {
    "CRITICAL": ["sms", "push", "email"],
    "URGENT": ["sms", "push"],
    "WARNING": ["push", "email"],
    "INFO": ["email"]
};
# Quiet hours for non-critical notifications (local time)
glob QUIET_HOURS: dict = {
    "start": 21,   # 9 PM
    "end": 8       # 8 AM
};
# Digest schedule
glob DIGEST_CONFIG: dict = {
    "day_of_week": 0,   # Monday (0=Monday)
    "hour_of_day": 9,   # 9 AM
    "timezone": "America/New_York"
};
# SMS message length limits
glob SMS_MAX_LENGTH: int = 160;
glob SMS_UNICODE_MAX_LENGTH: int = 70;

# Notification deduplication window (seconds)
glob DEDUP_WINDOW_SECONDS: int = 3600;

# Urgency thresholds for appeal deadline notifications
glob DEADLINE_ALERT_DAYS: list[int] = [60, 30, 14, 7, 3, 1];

"""Return notification channels to use for a given severity level."""
def get_channels_for_severity(severity: str) -> list[str] {
    return NOTIFICATION_ROUTING.get(severity, ["email"]);
}

"""Return True if the given hour is within quiet hours."""
def is_quiet_hours(hour: int) -> bool {
    start = QUIET_HOURS["start"];
    end = QUIET_HOURS["end"];
    if start > end {
        # Spans midnight
        return hour >= start or hour < end;
    }
    return start <= hour < end;
}

"""Truncate a message to SMS length limit."""
def truncate_sms(message: str) -> str {
    if len(message) <= SMS_MAX_LENGTH {
        return message;
    }
    return message[:SMS_MAX_LENGTH - 3] + "...";
}
