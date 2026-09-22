"""convert_experience_amount - Converts a string into a tuple of amount and type."""
def convert_experience_amount(amount: str) -> tuple[str, str] {
    xp_type = "levels";
    if isinstance(amount, str) {
        amount = amount.lower();
        if amount.endswith("p") {
            xp_type = "points";
        }
        if not amount.isdigit() {
            amount = amount[:-1];
        }
    }
    return (amount, xp_type);
}