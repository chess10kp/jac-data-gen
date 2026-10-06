"""PriorAuth node — prior authorization tracking."""

node PriorAuth {
    has auth_id: str = "",
        auth_number: str = "",
        service_requested: str = "",   # CPT code or service description
        medication_or_service_ref: str = "",  # Drug name or service description
        diagnosis_codes: list = [],
        requesting_provider: str = "",
        requesting_npi: str = "",
        facility: str = "",
        requested_date: str = "",      # Normalized field name
        date_requested: str = "",      # Legacy alias
        decision_date: str = "",
        date_approved: str = "",       # Legacy alias
        date_denied: str = "",         # Legacy alias
        expiry_date: str = "",
        valid_through: str = "",       # Alias for expiry_date
        approved_units: int = 0,
        used_units: int = 0,
        status: str = "PENDING",       # PENDING | UNDER_REVIEW | APPROVED | DENIED | EXPIRED | WITHDRAWN
        denial_reason: str = "",
        insurer_name: str = "",
        insurer_phone: str = "",
        appeal_deadline: str = "",
        notes: str = "",
        created_at: str = "";
}
