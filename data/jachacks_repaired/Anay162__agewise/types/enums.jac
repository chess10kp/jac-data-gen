"""Shared enumerations used across AgeWise."""

# Document classification categories
glob DOC_CATEGORIES: list[str] = [
    "EOB",
    "MEDICAL_BILL",
    "INSURANCE_CARD",
    "LEGAL_DOCUMENT",
    "PRESCRIPTION",
    "LAB_RESULT",
    "RADIOLOGY_REPORT",
    "DISCHARGE_SUMMARY",
    "PRIOR_AUTH",
    "APPEAL_LETTER",
    "UNKNOWN"
];

# Dispute error types
glob ERROR_TYPES: list[str] = [
    "DUPLICATE_CLAIM",
    "UPCODING",
    "UNBUNDLING",
    "WRONG_MODIFIER",
    "EXCEEDS_MUE",
    "CODING_ERROR",
    "NOT_COVERED",
    "BALANCE_BILLING",
    "PRIOR_AUTH_MISSING",
    "TIMELY_FILING",
    "COORDINATION_OF_BENEFITS"
];

# Dispute / appeal status
glob DISPUTE_STATUS: list[str] = [
    "OPEN",
    "SUBMITTED",
    "UNDER_REVIEW",
    "ESCALATED",
    "WON",
    "LOST",
    "WITHDRAWN",
    "EXPIRED"
];

# Appeal levels
glob APPEAL_LEVEL_NAMES: dict = {
    1: "Redetermination",
    2: "Reconsideration (QIC)",
    3: "ALJ Hearing",
    4: "Medicare Appeals Council",
    5: "Federal District Court"
};
# Severity levels
glob SEVERITY_LEVELS: list[str] = ["LOW", "MEDIUM", "HIGH", "CRITICAL"];

# Notification types
glob NOTIFICATION_TYPES: list[str] = [
    "APPEAL_DEADLINE",
    "LEGAL_EXPIRY",
    "BILL_DUE",
    "SCAM_ALERT",
    "DIGEST_READY",
    "CALL_COMPLETED",
    "ACTION_REQUIRED"
];

# Voice call statuses
glob CALL_STATUS: list[str] = [
    "PENDING",
    "INITIATED",
    "IN_PROGRESS",
    "COMPLETED",
    "FAILED",
    "NO_ANSWER",
    "VOICEMAIL"
];

# Insurance plan types
glob PLAN_TYPES: list[str] = [
    "MEDICARE_PART_A",
    "MEDICARE_PART_B",
    "MEDICARE_PART_C",
    "MEDICARE_PART_D",
    "MEDICAID",
    "MEDICARE_SUPPLEMENT",
    "COMMERCIAL",
    "VA",
    "TRICARE",
    "OTHER"
];
