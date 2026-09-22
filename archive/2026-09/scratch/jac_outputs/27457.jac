"""Sorting helper for members of a directory."""
def _sort_key(name: str) -> str {
    return name.lower().lstrip("_");
}