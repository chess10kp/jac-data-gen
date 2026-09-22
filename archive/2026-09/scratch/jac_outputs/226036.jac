"""Calculate social discount rate."""
def get_social_discount(t: int | float, r: float = 0.01) -> float {
    1 / (1 + r) ** t
}