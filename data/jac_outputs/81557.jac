"""Escape single quotes and wrap the value in double quotes."""
def shell_quote(var: str) -> str | None {
    _repr = repr(var);
    if _repr.startswith('\'') {
        return "\"%s\"" % _repr[1:-1];
    }
}