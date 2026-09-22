"""Check if triangle is possible."""
def is_triangle_possible(triangle: list[int | float]) -> bool {
    return sum(sorted(triangle)[:2]) > max(triangle);
}