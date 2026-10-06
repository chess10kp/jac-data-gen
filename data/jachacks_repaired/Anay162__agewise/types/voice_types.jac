"""Voice agent type definitions for call scripts and outcomes."""

# Call purpose categories
glob CALL_PURPOSES: list[str] = [
    "CLAIM_STATUS_INQUIRY",
    "APPEAL_SUBMISSION",
    "PRIOR_AUTH_REQUEST",
    "BENEFIT_VERIFICATION",
    "PROVIDER_INQUIRY",
    "BILLING_DISPUTE",
    "PRESCRIPTION_REFILL",
    "APPOINTMENT_SCHEDULING",
    "GENERAL_INQUIRY"
];

# IVR navigation intents
glob IVR_INTENTS: dict = {
    "main_menu": ["1", "2", "3", "4", "5", "0"],
    "claims": ["1", "claims", "claim status", "check claim"],
    "billing": ["2", "billing", "bill", "payment"],
    "provider": ["3", "provider", "doctor", "physician"],
    "benefits": ["4", "benefits", "coverage", "eligibility"],
    "representative": ["0", "operator", "representative", "agent", "human"],
    "repeat": ["9", "repeat", "say again"],
    "back": ["*", "back", "previous menu"]
};
# Call outcome categories
glob CALL_OUTCOMES: list[str] = [
    "INFORMATION_OBTAINED",
    "DISPUTE_SUBMITTED",
    "APPEAL_CONFIRMED",
    "CALLBACK_SCHEDULED",
    "TRANSFERRED_TO_AGENT",
    "VOICEMAIL_LEFT",
    "UNABLE_TO_RESOLVE",
    "NO_ANSWER",
    "WRONG_NUMBER",
    "DISCONNECTED"
];

# Bland.ai voice configurations
glob BLAND_VOICES: dict = {
    "professional_female": "maya",
    "professional_male": "ryan",
    "friendly_female": "sophie",
    "calm_male": "thomas"
};
# Standard hold/wait messages
glob WAIT_PHRASES: list[str] = [
    "Please hold while I check that for you.",
    "One moment please.",
    "I'm looking that up now.",
    "Thank you for your patience.",
    "I'm being transferred to the appropriate department."
];

# Medicare-specific phone numbers
glob MEDICARE_PHONES: dict = {
    "main": "1-800-633-4227",
    "ttd": "1-877-486-2048",
    "fraud": "1-800-HHS-TIPS",
    "omha": "1-855-556-8475",
    "appeals_council": "1-855-556-8475"
};