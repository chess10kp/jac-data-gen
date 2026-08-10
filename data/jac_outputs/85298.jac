"""Function to return text as bold."""
def bold(text: str) -> str {
    '\x1b[1;30m' + text + '\x1b[0m' if text else '\x1b[1;30m' + '\x1b[0m'
}