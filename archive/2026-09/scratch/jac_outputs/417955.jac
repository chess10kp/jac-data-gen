"""Find integration error if Simpson method is used."""
def calculate_integration_error(
    max_forth_derivative: float, low: float, high: float, length: int
) -> float {
    step = (high - low) / length;
    return step ** 4 / 180 * max_forth_derivative * (high - low);
}