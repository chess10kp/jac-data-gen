"""Convert a polyline to a sequence of lines."""
def polyline2linesegments[T](polyline: list[T]) -> list[tuple[T, T]] {
    if len(polyline) < 2 {
        raise ValueError("A polyline must have at least length 2");
    }
    [(p0, p1) for (p0, p1) in zip(polyline, polyline[1:])]
}