"""Unsanitizes a previously sanitized token."""
def unsanitize(t: str, mappings: dict[str, str]) -> str {
    final = t;
    for (original, sanitized) in mappings.items() {
        assert len(original) == 1;
        final = final.replace(sanitized, original);
    }
    return final;
}