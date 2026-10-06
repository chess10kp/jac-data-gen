"""Claim node — a medical claim submission.

Represents either a CMS-1500 (professional) or UB-04 (institutional) claim
with header-level data. Line items hang off this via has_line_item edges.
"""

node Claim {
    has claim_number: str = "",
        claim_type: str = "CMS1500",    # CMS1500 | UB04
        service_date_start: str = "",
        service_date_end: str = "",
        billing_date: str = "",
        total_charges: float = 0.0,
        amount_paid: float = 0.0,
        patient_responsibility: float = 0.0,
        status: str = "UNKNOWN",
        # SUBMITTED | PROCESSING | PAID | DENIED | PARTIAL | UNKNOWN
        payer_claim_id: str = "",       # insurer's internal claim number
        place_of_service: str = "",
        admission_date: str = "",
        discharge_date: str = "",
        type_of_bill: str = "",         # UB-04 FL4 (e.g. 0131)
        source_doc_id: str = "",        # reference to Document node
        created_at: str = "",
        updated_at: str = "";
}
