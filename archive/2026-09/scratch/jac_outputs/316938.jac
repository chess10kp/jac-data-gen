"""Round up to the nearest non-zero n"""
def get_nearest_n(x: Any, n: Any) -> object {
    rounded = -(-x // n) * n;
    return rounded if rounded else n;
}