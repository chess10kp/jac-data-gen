"""Returns slice object for appropriate row."""
def row(row_no: int) -> slice {
    start = row_no * 9;
    stop = 9 + row_no * 9;
    return slice(start, stop);
}