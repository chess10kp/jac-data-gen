"""Voice agent configuration — call provider settings and script parameters."""

import from os { environ }

# Active voice provider: "bland" | "vapi" | "twilio"
glob VOICE_PROVIDER: str = "bland";
glob MAX_CALL_DURATION_SECONDS: int = 1800;  # 30 minutes
glob CALL_RETRY_ATTEMPTS: int = 2;
glob CALL_RETRY_DELAY_HOURS: int = 4;

# Bland.ai configuration
glob BLAND_CONFIG: dict = {
    "base_url": "https://api.bland.ai/v1",
    "default_voice": "maya",
    "reduce_latency": True,
    "record": True,
    "wait_for_greeting": True,
    "amd": True,  # Answering machine detection
    "from_number": ""  # Set via BLAND_FROM_NUMBER env var
};
# Vapi.ai configuration
glob VAPI_CONFIG: dict = {
    "base_url": "https://api.vapi.ai",
    "default_assistant_id": "",  # Set via VAPI_ASSISTANT_ID env var
    "transcriber": "deepgram",
    "voice": "jennifer-playht"
};
# Call scheduling constraints
glob CALL_SCHEDULING: dict = {
    "allowed_hours_start": 9,   # 9 AM local time
    "allowed_hours_end": 17,    # 5 PM local time
    "allowed_days": [0, 1, 2, 3, 4],  # Mon-Fri (0=Monday)
    "hold_timeout_seconds": 600,
    "dtmf_gap_seconds": 1.5
};
# Medicare insurer phone numbers for IVR navigation
glob INSURER_PHONES: dict = {
    "MEDICARE": "1-800-633-4227",
    "MEDICARE_TTY": "1-877-486-2048",
    "MEDICAID": "",  # State-specific — set per patient state
    "AARP_SUPPLEMENT": "1-800-523-5800",
    "HUMANA": "1-800-457-4708",
    "UNITED": "1-877-699-5710",
    "CIGNA": "1-800-997-1654",
    "ANTHEM": "1-844-488-9981",
    "CVSHEALTHSPRING": "1-866-588-5122"
};
"""Return config for the active voice provider."""
def get_voice_provider_config() -> dict {
    provider = environ.get("VOICE_PROVIDER", VOICE_PROVIDER);
    if provider == "vapi" {
        return {**VAPI_CONFIG, "api_key": environ.get("VAPI_API_KEY", "")};
    }
    return {
        **BLAND_CONFIG,
        "api_key": environ.get("BLAND_API_KEY", ""),
        "from_number": environ.get("BLAND_FROM_NUMBER", "")
    };
}
