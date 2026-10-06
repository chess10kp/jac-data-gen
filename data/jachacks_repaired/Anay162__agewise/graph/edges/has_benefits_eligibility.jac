"""has_benefits_eligibility edge — Patient linked to a BenefitsEligibility screening."""

edge has_benefits_eligibility {
    has screening_date: str = "",
        screening_method: str = "AUTOMATED";  # AUTOMATED | MANUAL
}
