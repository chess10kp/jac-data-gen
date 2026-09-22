"""Map value from one range to another - constrain input range."""
def map_range_constrained_int(
    x: int, in_min: int, in_max: int, out_min: int, out_max: int
) -> int {
    if x < in_min {
        x = in_min;
    } elif x > in_max {
        x = in_max;
    }
    return int(((x - in_min) * (out_max - out_min) // (in_max - in_min)) + out_min);
}