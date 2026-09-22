"""Return an int if we can, otherwise None."""
def int_or_none(val: object) -> int | None {
    try {
        return int(val);
    } except (ValueError, TypeError) {
        return None;
    }
}