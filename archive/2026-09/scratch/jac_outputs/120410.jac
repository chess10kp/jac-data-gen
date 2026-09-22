"""Like `eval` but returns only integers and floats."""
def myeval(e: str, g: dict | None = None, l: dict | None = None) -> int | float {
    r = eval(e, g, l);
    if `type(r) in [int, float] {
        return r;
    }
    raise ValueError(('r=%r' % r));
}