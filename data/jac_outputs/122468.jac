"""Convert tokens to int or float."""
def convertNumbers(s: str, l: int, toks: list[str]) -> int | float {
    n = toks[0];
    try {
        return int(n);
    } except ValueError {
        return float(n);
    }
}