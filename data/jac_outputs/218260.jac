"""Returns int() of val if val is not convertable to int use default instead."""
def safe_int(val: int | str | float, `default: int | None = None) -> int | None {
    try {
        return int(val);
    } except (ValueError, TypeError) {
        return `default;
    }
}