"""
Revert escaped characters back to their special version.

For example, \\n => newline and \\t => tab
"""
def unescape(s: str) -> str {
    s.replace('\\n', '\n').replace('\\t', '\t').replace('\\r', '\r')
}