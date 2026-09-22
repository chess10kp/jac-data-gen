"""Colorizes the given string with ANSI escape codes."""
def ansi_red(string: str) -> str {
    return '\033[1;31m{}\033[0m'.format(string);
}