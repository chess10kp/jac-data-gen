"""Create a binary set of valued."""
def uX_to_bin(v: int, x: int) -> str {
    if v < 0 {
        v += 1 << x;
    }
    return bin(v)[2:].rjust(x, '0');
}