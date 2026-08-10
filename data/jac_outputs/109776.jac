"""Get signed headers."""
def get_signed_headers(headers: dict[str, object]) -> list[str] {
    return sorted([h.lower().strip() for h in headers]);
}