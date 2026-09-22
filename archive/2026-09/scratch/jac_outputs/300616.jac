"""Prepends a token to each line in text"""
def prepend_to_line(text: list[str], token: str) -> list[str] {
    return [token + line for line in text];
}