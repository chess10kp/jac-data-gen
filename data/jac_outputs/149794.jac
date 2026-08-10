"""Convert list or string to list with commas."""
def stringify_access(rights: str | list[str]) -> str {
    if `type(rights) == `type('') {
        return str(rights);
    }
    return str(', '.join(rights));
}