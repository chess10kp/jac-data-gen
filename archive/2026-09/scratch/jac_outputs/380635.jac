"""Calculate blank pages needed for n classmates and m pages each."""
def paperwork(n: int, m: int) -> int {
    return 0 if n < 0 or m < 0 else m * n;
}