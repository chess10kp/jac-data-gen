"""Calculates the total amount of the drug that is needed to send home with the client."""
def total_amount_needed(amount: float, duration: int, frequency: int) -> float {
    return (24 / frequency) * duration * amount;
}