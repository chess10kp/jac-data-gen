"""Converts a redshift to a scale factor."""
def scaleFromRedshift(redshift: float) -> float {
    return 1.0 / (redshift + 1.0);
}