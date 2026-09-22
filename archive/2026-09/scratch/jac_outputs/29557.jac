"""Add leading 0."""
def zeroPad(n: int | str, l: int) -> str {
    return str(n).zfill(l);
}