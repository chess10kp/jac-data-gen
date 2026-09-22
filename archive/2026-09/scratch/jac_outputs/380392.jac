"""Utility function that gives the correct string ordinal given a number."""
def ordinal(n: int) -> str {
    return "%d%s" % (n, "tsnrhtdd"[((n // 10 % 10 != 1) * (n % 10 < 4) * n) % 10::4]);
}