"""BeneficiaryDesignation node — beneficiary on a financial account.

Tracks who inherits what for each financial account, with per stirpes
vs per capita distribution.
"""

node BeneficiaryDesignation {
    has designation_id: str = "",
        account_ref: str = "",          # financial account identifier
        account_type: str = "",
        primary_beneficiaries: list[str] = [],
        contingent_beneficiaries: list[str] = [],
        share_percentages: list[float] = [],
        distribution_method: str = "per_stirpes",  # per_stirpes | per_capita
        last_updated: str = "",
        is_complete: bool = False,      # all % add to 100%
        needs_review: bool = False,
        review_reason: str = "";
}
