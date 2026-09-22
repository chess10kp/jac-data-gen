"""Converts unicode string to string of integers in uppercase hex.

Integers correspond to the codepoints within the string. Each integer is
followed by a space.
"""
def _CodepointString(unicode_text: str) -> str {
    return " ".join("%04X" % ord(c) for c in unicode_text);
}