"""Returns fur's default parameter range as 2-tuple (min, max)."""
def _getParameterRange(key: str) -> tuple[float, float] {
    match key {
        case "Density":
            return (10000.0, 30000.0);
        case "Length":
            return (1.0, 5.0);
        case "BaseWidth":
            return (0.01, 0.1);
        case "TipWidth":
            return (0.0, 0.1);
        case "Inclination":
            return (0.0, 0.9);
        case "PolarNoise":
            return (0.0, 0.5);
        case "PolarNoiseFreq":
            return (1.0, 20.0);
        case "BaseCurl":
            return (0.5, 1.0);
        case "TipCurl":
            return (0.0, 1.0);
        case "Scraggle":
            return (0.0, 0.5);
        case "ScraggleCorrelation":
            return (0.0, 0.5);
        case "ScraggleFrequency":
            return (1.0, 10.0);
        case "Clumping":
            return (0.0, 0.5);
        case "ClumpingFrequency":
            return (1.0, 50.0);
        case "ClumpShape":
            return (1.0, 5.0);
        case "SpecularSharpness":
            return (0.0, 100.0);
        case _:
            return (0.0, 1.0);
    }
}