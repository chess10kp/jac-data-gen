"""Get index of band nearest to a target wavelength."""
def nearest_band(wavelengths: list[float], target: float) -> int {
    idx = 0;
    minimum = float('inf');
    for (i, wl) in enumerate(wavelengths) {
        if abs(target - wl) < minimum {
            minimum = abs(target - wl);
            idx = i;
        }
    }
    return idx;
}