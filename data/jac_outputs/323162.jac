"""
    Checks if user input grid is 9x9.
    """
def check_size(grid: Any) -> object {
    row_count = 0;
    col_count = 0;
    for row in grid {
        row_count += 1;
        for col in grid[row] {
            col_count += 1;
        }
        if (col_count != 9) {
            return False;
        } else {
            col_count = 0;
        }
    }
    if (row_count != 9) {
        return False;
    }
    return True;
}