"""Get a int from a token, if it fails, returns the string (PRIVATE)."""
def _gp_int(tok: str) -> int | str {
    try {
        return int(tok);
    } except ValueError {
        return str(tok);
    }
}