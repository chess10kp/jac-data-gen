"""
Wrap ``code`` with the special characters to tell readline that it is
invisible.
"""
def readline_invisible(code: str) -> str {
    return f'\001{code}\002';
}