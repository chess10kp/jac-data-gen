"""BenefitsEligibility node — tracks program eligibility screening results."""

node BenefitsEligibility {
    has eligibility_id: str = "",
        program_name: str = "",
        program_type: str = "",  # MSP | EXTRA_HELP | MEDICAID | SNAP | LIHEAP | etc.
        is_eligible: bool = False,
        confidence_score: float = 0.0,
        eligibility_reason: str = "",
        estimated_savings_monthly: float = 0.0,
        application_url: str = "",
        application_phone: str = "",
        application_deadline: str = "",
        screened_date: str = "",
        applied_date: str = "",
        approved_date: str = "",
        status: str = "SCREENED",  # SCREENED | APPLIED | APPROVED | DENIED | ENROLLED
        notes: str = "",
        created_at: str = "";
}
