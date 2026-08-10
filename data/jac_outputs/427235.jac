"""Calculate service fee proportional to the principal (fee = principal × fee rate)."""
def linear_service_fee(principal: float | int, fee: float = 0.0) -> float {
    return float(principal * fee);
}