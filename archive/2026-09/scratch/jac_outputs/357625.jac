glob PHASE_FLAG_MASK = 96;

"""
    Returns the layer thermodynamical phase, as identified from the
    feature classification flag

    0 = unknown / not determined 1 = randomly oriented ice
    2 = water
    3 = horizontally oriented ice
    """
def phase(flags: int) -> int {
    return (flags & PHASE_FLAG_MASK) >> 5;
}