"""Convert a list of polygons into an array of tight bounding boxes."""
def poly_to_box(poly: list[list[int]]) -> list[int] {
    x0 = min(min(p[::2]) for p in poly);
    x1 = max(max(p[::2]) for p in poly);
    y0 = min(min(p[1::2]) for p in poly);
    y1 = max(max(p[1::2]) for p in poly);
    return [x0, y0, x1, y1];
}