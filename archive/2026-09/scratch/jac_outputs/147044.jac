"""Calculates the density of glycerol from an interpolation by Cheng."""
def densityGlycerol(temperature: float) -> float {
    return 1277 - 0.654 * temperature;
}