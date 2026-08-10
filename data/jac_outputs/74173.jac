"""
    Calculates and returns two lists.
    The first list consists of x-coordinates of all bar lines.
    The second list consists of y-coordinates of all center staff lines.
    """
def calculate_grid_points(
    size: tuple[int, int],
    buffer: int,
    bars_per_line: int,
    lines_per_page: int
) -> tuple[list[float], list[float]] {
    x_list = [];
    y_list = [];
    for i in range(bars_per_line + 1) {
        x_list.append(buffer + i * (size[0] - 2 * buffer) / bars_per_line);
    }
    for i in range(lines_per_page) {
        y_list.append(
            buffer
            + (size[1] - 2 * buffer) / lines_per_page / 2
            + i * (size[1] - 2 * buffer) / lines_per_page
        );
    }
    return (x_list, y_list);
}