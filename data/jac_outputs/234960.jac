"""Get maximum intensity for a given bitdepth.
To get number of possible intensities, set `count` to True."""
def max_intensity(bitdepth: int, count: bool = False) -> int {
    mi = 2 ** bitdepth;
    if not count {
        mi -= 1;
    }
    return mi;
}