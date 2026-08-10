import re;

"""Removes all ANSI escape codes from a given string."""
def undecorate(string: str) -> str {
    return re.sub(r'\033\[[^m]+m', '', string);
}