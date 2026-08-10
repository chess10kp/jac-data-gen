"""Round up to multiple of 2**exp."""
def align(num: int, exp: int) -> int {
    mask = (2 ** exp) - 1;
    return (num + mask) & ~mask;
}