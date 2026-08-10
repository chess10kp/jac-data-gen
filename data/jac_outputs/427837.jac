"""Sort string punctuation, lowercase and then uppercase."""
def sort_string(text: str) -> str {
    return ''.join(sorted(text, key=str.swapcase));
}