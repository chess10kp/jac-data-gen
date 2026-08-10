"""Returns the value of an expression given x."""
def convert(f: str | Callable[[float], float], x: float) -> float {
    if isinstance(f, str) {
        return eval(f);
    }
    return f(x);
}