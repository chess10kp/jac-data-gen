"""Replaces the old suffix of the original string by a new suffix."""
def suffix_replace(original: str, old: str, new: str) -> str {
    return original[:-len(old)] + new;
}