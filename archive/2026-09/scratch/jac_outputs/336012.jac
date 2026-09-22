"""Parse a hex number from text or fail."""
def parse_hex(text: str) -> int {
    try {
        return int(text, 0);
    } except ValueError as ex {
        raise RuntimeError(f"Could not parse hex number '{text}': {ex}");
    }
}