"""RecordsTransfer node — tracks medical records transfer requests."""

node RecordsTransfer {
    has transfer_id: str = "",
        purpose: str = "",                    # Reason / context for the transfer
        requested_date: str = "",             # ISO date of request
        request_date: str = "",               # Legacy alias
        requested_records: list = [],         # List of record types requested
        sending_provider_name: str = "",      # from_provider alias (display name)
        sending_provider_phone: str = "",
        from_provider: str = "",
        from_npi: str = "",
        receiving_provider_name: str = "",    # to_provider alias (display name)
        to_provider: str = "",
        to_npi: str = "",
        patient_consent_date: str = "",
        hipaa_auth_generated: bool = False,
        status: str = "PENDING",              # PENDING | CALL_QUEUED | REQUESTED | IN_TRANSIT | RECEIVED | DENIED | CANCELLED
        completion_date: str = "",
        received_date: str = "",
        pages_transferred: int = 0,
        fee_charged: float = 0.0,
        hipaa_compliant: bool = True,
        notes: str = "",
        created_at: str = "";
}
