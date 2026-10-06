"""Policy node — a specific insurance coverage policy.

Stores the coverage terms, effective dates, and plan details.
The coverage_policy_checker walker walks patient → policy to
validate whether services are covered.
"""

node Policy {
    has policy_id: str = "",
        plan_id: str = "",
        plan_name: str = "",
        plan_type: str = "",
        # MEDICARE_PART_A | MEDICARE_PART_B | MEDICARE_ADVANTAGE |
        # MEDIGAP | PART_D | MEDICAID | COMMERCIAL
        group_number: str = "",
        member_id: str = "",
        effective_date: str = "",
        termination_date: str = "",
        deductible_individual: float = 0.0,
        deductible_met: float = 0.0,
        out_of_pocket_max: float = 0.0,
        out_of_pocket_met: float = 0.0,
        copay_primary: float = 0.0,
        copay_specialist: float = 0.0,
        coinsurance_rate: float = 0.20,  # patient's share (20% = 0.20)
        coverage_summary: str = "",
        formulary_tier: int = 0,
        plan_year: str = "";
}
