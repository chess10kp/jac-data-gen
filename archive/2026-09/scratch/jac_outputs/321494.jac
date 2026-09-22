"""Escapes the string 'a' for use inside a CMake string.

This means escaping
'\\' otherwise it may be seen as modifying the next character
'"' otherwise it will end the string
';' otherwise the string becomes a list."""
def CMakeStringEscape(a: str) -> str {
    return a.replace('\\', '\\\\').replace(';', '\\;').replace('"', '\\"');
}