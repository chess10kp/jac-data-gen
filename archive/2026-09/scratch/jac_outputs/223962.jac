"""Find the index of the first triangle containing the given vertex."""
def _find_triangle_containing_vertex(vertex: int, triangles: list[tuple[int, int, int]]) -> int | None {
    triangle_index = None;
    for (triangle_i, triangle) in enumerate(triangles) {
        if vertex in triangle {
            triangle_index = triangle_i;
        }
    }
    return triangle_index;
}