"""Recursively replace a string in a string"""
def rec_replace(in_str: str, old: str, new: str) -> str {
    if old == new {
        return in_str;
    }
    if old not in in_str {
        return in_str;
    }
    return rec_replace(in_str.replace(old, new), old, new);
}