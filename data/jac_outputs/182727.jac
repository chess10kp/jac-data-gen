"""returns the text with "toRemove" stripped from the start if it matches."""
def removeFromStart(text: str, toRemove: str, ignoreCase: int | bool | None = None) -> str {
    text2: str;
    prefix: str;
    if ignoreCase {
        text2 = text.lower() as str;
        prefix = toRemove.lower() as str;
    } else {
        text2 = text;
        prefix = toRemove;
    }
    if text2.startswith(prefix) {
        return text[len(prefix):];
    }
    return text;
}