"""Convert coordinates to zero-based, both strand, open/closed coordinates.

     Parameters are from, to, is_positive_strand, length of contig."""
def _zero_forward_closed(x: int, y: int, c: bool, l: int) -> tuple[int, int] {
    y += 1;
    if not c {
        (x, y) = (l - y, l - x);
    }
    return (x, y);
}