"""LegalDocument node — estate planning and authorization documents.

Tracks wills, trusts, powers of attorney, and HIPAA authorizations
with expiry monitoring.
"""

node LegalDocument {
    has legal_doc_id: str = "",
        doc_type: str = "",
        # WILL | TRUST | POWER_OF_ATTORNEY | HIPAA_AUTH | LIVING_WILL |
        # HEALTHCARE_PROXY | BENEFICIARY_FORM
        title: str = "",
        effective_date: str = "",
        expiry_date: str = "",          # empty = no expiration
        jurisdiction: str = "",
        parties: list[str] = [],        # names of all parties
        executor_agent: str = "",       # executor (will) or agent (POA)
        trustee: str = "",
        key_provisions: list[str] = [], # extracted key terms
        plain_english_summary: str = "",
        source_doc_id: str = "",
        status: str = "ACTIVE",         # ACTIVE | EXPIRED | REVOKED | PENDING
        days_until_expiry: int = -1,    # -1 = no expiry
        attorney_reviewed: bool = False,
        created_at: str = "";
}
