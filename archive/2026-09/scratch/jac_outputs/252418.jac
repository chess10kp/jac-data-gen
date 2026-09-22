"""Replace all non-breaking space symbols with a space symbol."""
def replace_nbsp(text: str) -> str {
    return text.replace("\u00a0", "\u0020");
}