glob MAX_WAVENUMBER = 6000;
glob POINTS_PER_CM = 8;

"""converts a wavenumber to index. Assuming there are 6000 cm^-1 and
    8 points/cm^-1.
    """
def waveindex(value: float) -> int {
    return int((MAX_WAVENUMBER - value) * POINTS_PER_CM);
}