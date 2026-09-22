"""Returns string with its first character decapitalized (if any)."""
def decapitalize_first(string: str) -> str {
    string[:1].lower() + string[1:]
}