"""Decide whether y < f(x), but where "<" can be specified."""
def cmp_func(y: float, behavior: str, f: Callable[[float], float], x: float) -> bool {
    if behavior == 'less' {
        return y < f(x);
    } elif behavior == 'greater' {
        return y > f(x);
    } else {
        raise ValueError("behavior must be 'less' or 'greater'. Got %s " % behavior);
    }
}