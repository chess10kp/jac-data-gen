"""Convert hex numbers, return original string on failure."""
def numberify(x: str) -> int | str {
    try {
        return int(x, 16);
    } except ValueError {
        return x;
    }
}