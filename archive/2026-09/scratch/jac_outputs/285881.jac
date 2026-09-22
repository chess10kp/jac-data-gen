"""Check whether quote is truly end of a sentence."""
def _ignore_quote(pos: int, text: str) -> int {
    if pos + 3 < len(text) and text[pos + 3].islower() {
        return -1;
    }
    return pos;
}