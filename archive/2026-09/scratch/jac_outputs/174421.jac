"""Returns the scanner position in a layer after a given number of picoseconds."""
def get_scanner(time: int, height: int) -> int {
    offset = time % ((height - 1) * 2);
    if offset > height - 1 {
        position = 2 * (height - 1) - offset;
    } else {
        position = offset;
    }
    return position;
}