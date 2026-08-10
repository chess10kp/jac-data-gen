"""Returns key with maximum value in dictionary."""
def dictmax(d: dict[str, int]) -> str {
    max(d.keys(), key=lambda (x: str) { d[x] })
}