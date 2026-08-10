"""Returns the midpoint value of the quadrant a component lies."""
def _adjust_component(value: int) -> int {
    midpt = 0;
    if 255 >= value >= 192 {
        midpt = 223;
    }
    if 191 >= value >= 128 {
        midpt = 159;
    }
    if 127 >= value >= 64 {
        midpt = 95;
    }
    if 63 >= value >= 0 {
        midpt = 31;
    }
    return midpt;
}