"""Return the cell that has been clicked on with the mouse."""
def get_mouse_pos(mouse_pos: tuple[int, int], rows: int, width: int) -> tuple[int, int] {
    cell_width = width // rows;
    (y, x) = mouse_pos;
    row = y // cell_width;
    col = x // cell_width;
    return (row, col);
}