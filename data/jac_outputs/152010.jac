"""Replaces each null character (\\0) in the input with \\\\0."""
def escape_null(s: str) -> str {
    s.replace("\0", "\\0")
}