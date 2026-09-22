"""Convert text to lowercase, replace periods and commas, and split it into a list."""
def __tokenize_text(text: str) -> list[str] {
    text.lower().replace(',', '').replace('.', '').split()
}