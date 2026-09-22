"""Escapes Discord formatting in the given string."""
def escape_formatting(username: str) -> str {
    username.replace("_", "\\_").replace("*", "\\*")
}