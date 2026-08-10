"""Convert bytes to MB."""
def b_to_mb(b: int) -> float {
    round(float(b) / (1024 ** 2), 2)
}