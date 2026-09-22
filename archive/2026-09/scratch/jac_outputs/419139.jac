"""Undo parse_address()."""
def unparse_address(scheme: str, loc: str) -> str {
    return f'{scheme}://{loc}';
}