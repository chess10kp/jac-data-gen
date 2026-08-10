"""Divide x by y and round the result upwards."""
def divup(x: int, y: int) -> int {
    return (x + y - 1) // y;
}