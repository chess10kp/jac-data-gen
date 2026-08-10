"""Convert from possible bytes without interpreting as number."""
def _str(text: str | bytes) -> str {
    return text.decode("utf-8") if isinstance(text, bytes) else text;
}