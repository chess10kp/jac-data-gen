"""Check if a point is inside an axis-aligned rectangle."""
def point_in_rectangle(px: int | float, py: int | float, rectangle: list[list[int | float]]) -> bool {
    max_x_val = float("-inf");
    max_y_val = float("-inf");
    min_x_val = float("inf");
    min_y_val = float("inf");
    assert len(rectangle) == 4;
    for p in rectangle {
        if p[0] >= max_x_val { max_x_val = p[0]; }
        if p[1] >= max_y_val { max_y_val = p[1]; }
        if p[0] <= min_x_val { min_x_val = p[0]; }
        if p[1] <= min_y_val { min_y_val = p[1]; }
    }
    return px >= min_x_val and px <= max_x_val and py >= min_y_val and py <= max_y_val;
}