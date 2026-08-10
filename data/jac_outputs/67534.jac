"""Make StatusCode name pretty again."""
def _pretty(name: str) -> str {
    name.replace("_", " ").lower().title()
}