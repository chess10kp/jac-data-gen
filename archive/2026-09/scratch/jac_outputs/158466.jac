"""Returns True if color can be classified as a shade of red."""
def RedFilter(c: list[int]) -> bool {
    return c[0] > c[1] and c[0] > c[2] and c[1] == c[2];
}