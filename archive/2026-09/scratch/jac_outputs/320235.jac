"""Locate the most negative entry in the last row excluding the last column."""
def find_pivot_column(last_row: list[float]) -> int {
    m = 0.0;
    column_index = -1;
    for (i, `entry) in enumerate(last_row) {
        if `entry < 0 and `entry < m {
            m = `entry;
            column_index = i;
        }
    }
    return column_index;
}