"""Try converting the value to a number."""
def parse_number(value: str | int | float) -> float | None {
    try {
        return float(value);
    } except ValueError {
        return None;
    }
}