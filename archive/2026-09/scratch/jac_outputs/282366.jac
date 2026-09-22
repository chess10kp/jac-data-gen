"""Returns the smallest greater than x, power of 2 value."""
def next_power_of_2(x: int) -> int {
    x = int(x);
    return 1 if x == 0 else 2 ** (x - 1).bit_length();
}