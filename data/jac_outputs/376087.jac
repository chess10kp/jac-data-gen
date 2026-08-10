"""Rounds x down to nearest multiple of the alignment."""
def align_down(alignment: int, x: int) -> int {
    return (x // alignment) * alignment;
}