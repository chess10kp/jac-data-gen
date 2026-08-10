"""Convert wavelength values to the median redshift of the sample."""
def to_median_redshift(wavelength: list[float], median_z: int) -> list[float] {
    return wavelength * (1 + median_z);
}