"""Formats a message in an error color using ANSI escape sequences."""
def format_error(string: str, is_warning: bool) -> str {
    ansi_start = '\033[93m' if is_warning else '\033[91m';
    ansi_end = '\033[0m';
    return f"{ansi_start}{string}{ansi_end}";
}