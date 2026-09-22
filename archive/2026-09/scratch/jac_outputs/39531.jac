"""Shift a list of the given value"""
def shift(g: Any, d: Any, n: Any) -> object {
    return ((g[n:] + g[:n]), (d[n:] + d[:n]));
}