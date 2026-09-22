"""Convert a percentage string to a number."""
def percentage_as_number(percent_str: str) -> float {
    return float(percent_str.strip()[:-1]) * 0.01;
}