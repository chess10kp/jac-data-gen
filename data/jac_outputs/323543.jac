"""Convert the given candidate to int. If it fails None is returned."""
def try_parse_int(candidate: int | str | float | bool) -> int | None {
    try {
        return int(candidate);
    } except (ValueError, TypeError) {
        return None;
    }
}