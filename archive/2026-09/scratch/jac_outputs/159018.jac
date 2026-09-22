"""The square of the distance between two (x, y) points."""
def distance_squared(a: Any, b: Any) -> object {
    return (((a[0] - b[0]) ** 2) + ((a[1] - b[1]) ** 2));
}