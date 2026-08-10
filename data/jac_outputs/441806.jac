"""Groups the given text into n-letter groups separated by spaces."""
def group_text(text: str, n: int = 5) -> str {
    return " ".join("".join(text[i:(i + n)]) for i in range(0, len(text), n));
}