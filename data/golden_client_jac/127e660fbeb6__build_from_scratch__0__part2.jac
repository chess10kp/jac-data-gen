"""Format a count as 'N signature(s)', pluralizing unless the count is exactly 1."""

def _signature_phrase(signatures: int) -> str {
    plural = "s" if signatures != 1 else "";
    return f"{signatures} signature{plural}";
}

with entry {
    for n in [0, 1, 2, 5, -1] {
        print(_signature_phrase(n));
    }
}
