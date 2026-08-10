"""Strips a prefix from a string, if the string starts with the prefix."""
import re;

def strip_prefix(string: str, strip: str) -> str {
    strip_esc = re.escape(strip);
    if re.match(strip_esc, string) {
        return string[len(strip):];
    }
    return string;
}