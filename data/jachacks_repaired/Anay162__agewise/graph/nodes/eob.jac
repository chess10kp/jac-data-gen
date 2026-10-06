"""EOB (Explanation of Benefits) / MSN (Medicare Summary Notice) node.

Stores the payer's adjudication decision for a claim. The discrepancy
between what was billed (Claim) and what the EOB says is the core
source of disputes.
"""

node EOB {
    has eob_id: str = "",
        eob_type: str = "UNKNOWN",
        # MSN_PART_A | MSN_PART_B | ADVANTAGE_EOB | MEDIGAP_EOB | PART_D
        payer_name: str = "",
        adjudication_date: str = "",
        total_billed: float = 0.0,
        medicare_approved: float = 0.0,
        medicare_paid: float = 0.0,
        patient_responsibility: float = 0.0,
        non_covered_charges: float = 0.0,
        benefit_days_used: int = 0,
        appeal_deadline: str = "",      # computed from adjudication_date
        denial_codes: list[str] = [],   # reason codes for denials
        denial_reasons: list[str] = [], # human-readable denial reasons
        source_doc_id: str = "",
        created_at: str = "";
}
