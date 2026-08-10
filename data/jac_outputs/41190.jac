"""Convert a thing to an integer."""
def as_int(x: str | int | float, `default: int = 0) -> int {
    try {
        return int(x);
    } except ValueError {
        return `default;
    }
}