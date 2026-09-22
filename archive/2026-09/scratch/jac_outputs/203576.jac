"""A basic slug version of a given parameter list."""
def delistify(x: list[str] | str) -> str {
    if isinstance(x, list) {
        x = [e.replace("'", "") for e in x];
        return '-'.join(sorted(x));
    }
    return x;
}