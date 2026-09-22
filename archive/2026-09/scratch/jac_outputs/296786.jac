"""Data min-max normalization."""
def normalize(x: float, min: float, max: float) -> float {
    (x - min) / (max - min)
}