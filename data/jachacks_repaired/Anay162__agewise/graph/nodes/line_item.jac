"""LineItem node — a single service line within a claim.

Corresponds to Box 24 on CMS-1500 or revenue code lines on UB-04.
This is where billing errors live — wrong CPT codes, incorrect units,
unbundled procedures, etc.
"""

node LineItem {
    has line_number: int = 1,
        cpt_code: str = "",             # CPT or HCPCS procedure code
        revenue_code: str = "",         # UB-04 revenue code (FL 42)
        icd_diagnosis_pointers: list[str] = [],  # pointer A-L → ICD codes
        modifier_1: str = "",
        modifier_2: str = "",
        modifier_3: str = "",
        units: float = 1.0,
        charge_amount: float = 0.0,
        allowed_amount: float = 0.0,
        paid_amount: float = 0.0,
        place_of_service_code: str = "",
        service_date: str = "",
        description: str = "",          # human-readable service description
        # Error detection results (populated by audit walkers)
        fee_schedule_rate: float = 0.0,
        fee_schedule_overage: float = 0.0,
        mue_limit: int = 0,
        ncci_flags: list[str] = [],
        has_errors: bool = False,
        error_count: int = 0;
}
