"""Format a string in cyan."""
def cyan(x: str) -> str {
    f"\033[36m{x}\033[0m"
}