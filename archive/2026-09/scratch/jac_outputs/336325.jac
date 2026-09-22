"""
    Returns the integer value of a string if possible,
    else None
    """
def maybe_int(string: str) -> int | None {
    try {
        return int(string);
    } except ValueError {
        return None;
    }
}