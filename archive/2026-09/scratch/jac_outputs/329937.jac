"""Round integer `x` up to the next possible multiple of `mult`."""
def round_up_next_multiple(x: int, mult: int) -> int {
    rem = x % mult;
    if rem > 0 {
        return x - rem + mult;
    }
    return x;
}