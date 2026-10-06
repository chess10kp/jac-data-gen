"""Prescription node — tracks prescribed medications."""

node Prescription {
    has prescription_id: str = "",
        drug_name: str = "",
        generic_name: str = "",
        ndc: str = "",                # NDC code (normalized)
        ndc_code: str = "",           # Legacy alias
        dosage: str = "",
        sig: str = "",                # Directions (e.g. "1 tablet by mouth twice daily")
        quantity: int = 0,
        days_supply: int = 30,
        days_remaining: int = 0,
        refills_remaining: int = 0,
        prescriber_name: str = "",
        prescriber_npi: str = "",
        pharmacy_name: str = "",
        pharmacy_ncpdp: str = "",
        last_fill_date: str = "",     # Date of most recent fill
        fill_date: str = "",          # Legacy alias
        next_fill_due: str = "",      # Computed next fill date
        next_fill_date: str = "",     # Legacy alias
        tier: int = 1,                # Formulary tier 1-5
        copay: float = 0.0,
        is_active: bool = True,
        status: str = "ACTIVE",       # ACTIVE | DISCONTINUED | TRANSFERRED | EXPIRED
        created_at: str = "";
}
