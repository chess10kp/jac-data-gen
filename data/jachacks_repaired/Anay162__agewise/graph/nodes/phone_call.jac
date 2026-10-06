"""PhoneCall node — a voice agent call session.

Created when the voice agent makes an outbound call (to insurer,
provider, pharmacy, etc.). Stores the transcript and outcome.
"""

node PhoneCall {
    has call_id: str = "",
        call_type: str = "",
        # BILLING_DISPUTE | CLAIM_STATUS | PRIOR_AUTH_FOLLOWUP | APPOINTMENT_RESCHEDULE |
        # PHARMACY_INQUIRY | RECORDS_REQUEST | RECORDS_FOLLOWUP |
        # SUBSCRIPTION_CANCELLATION | GOVERNMENT_AGENCY
        purpose: str = "",              # Human-readable reason for the call
        provider_api: str = "bland",    # bland | vapi
        external_call_id: str = "",     # Call ID from voice API provider
        status: str = "QUEUED",         # QUEUED | IN_PROGRESS | COMPLETED | FAILED
        initiated_at: str = "",
        ended_at: str = "",
        duration_seconds: int = 0,
        target_phone: str = "",         # Phone number to call
        target_name: str = "",          # Organization/person being called
        to_phone: str = "",             # Legacy alias for target_phone
        to_name: str = "",              # Legacy alias for target_name
        outcome: str = "PENDING",
        # PENDING | RESOLVED | ESCALATED | NO_ANSWER | VOICEMAIL | FAILED
        outcome_summary: str = "",
        recording_url: str = "",
        transcript: str = "",
        action_items: list = [],        # extracted from transcript by llm
        reference_numbers: list = [],
        created_at: str = "";
}
