"""Medication node — canonical drug record for a patient's active medication list.

Built by MedicationListBuilder from Prescription nodes. Serves as the
deduplicated master record used by DrugInteractionChecker.
"""

node Medication {
    has medication_id: str = "",
        drug_name: str = "",         # Brand name (e.g. "Lipitor")
        generic_name: str = "",      # Generic name (e.g. "atorvastatin")
        brand_name: str = "",
        ndc: str = "",               # National Drug Code
        strength: str = "",          # e.g. "20mg"
        form: str = "",              # TABLET | CAPSULE | LIQUID | INJECTION | PATCH
        therapeutic_class: str = "", # e.g. "Statin", "ACE Inhibitor"
        active_ingredient: str = "",
        prescribing_provider: str = "",
        prescribing_provider_npi: str = "",
        pharmacy_name: str = "",
        last_filled: str = "",       # ISO date
        days_supply: int = 30,
        refills_remaining: int = 0,
        next_fill_due: str = "",     # ISO date (computed: last_filled + days_supply)
        days_until_refill: int = 0,  # Negative = overdue
        known_interactions: list[str] = [],
        active: bool = True,
        start_date: str = "",
        end_date: str = "",
        created_at: str = "";
}
