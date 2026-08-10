"""Clean text by removing extra spaces between words."""
def clean_text(raw_text: str) -> str {
    return ' '.join(raw_text.split());
}