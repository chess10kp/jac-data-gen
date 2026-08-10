"""Formats the string name to be used in a --version flag."""
def _format_version(name: str) -> str {
    return name.replace("-", "_");
}