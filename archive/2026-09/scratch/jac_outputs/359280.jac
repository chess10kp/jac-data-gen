"""The weigher function."""
def weigher(r: int, method: str = 'hyperbolic') -> float {
    if method == 'hyperbolic' {
        return 1 / (r + 1);
    }
    raise Exception('Unknown method: {}'.format(method));
}