"""BenefitsReport node — aggregated report of government benefit eligibility screening."""

node BenefitsReport {
    has report_id: str = "",
        report_date: str = "",
        programs_screened: list = [],            # list of program names
        programs_eligible: list = [],            # programs where patient likely qualifies
        total_potential_monthly_value: float = 0.0,
        total_potential_annual_value: float = 0.0,
        application_status_map: dict = {},       # {program: status}
        summary_text: str = "",
        next_review_date: str = "",
        created_at: str = "";
}
