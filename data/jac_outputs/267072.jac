"""Convert string to float."""
def to_float(string: str) -> float {
    try {
        number = float(string);
    } except Exception {
        number = 0.0;
    }
    return number;
}