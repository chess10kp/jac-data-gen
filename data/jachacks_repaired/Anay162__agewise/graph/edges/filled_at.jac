"""filled_at edge — Prescription filled at a Pharmacy."""

edge filled_at {
    has fill_date: str = "",
        fill_number: int = 1,
        copay_amount: float = 0.0;
}
