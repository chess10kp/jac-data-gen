""":nonempty: Any text. Returns '(none)' if the string is empty."""
def nonempty(str: str) -> str {
    str or "(none)"
}