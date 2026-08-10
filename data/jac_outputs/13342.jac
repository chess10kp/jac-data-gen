"""Return round of the input number respected to the digit."""
def custom_rounder(input_number: float, p: int) -> float {
    return int(input_number * p + 0.5) / p;
}