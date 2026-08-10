"""Undo preprocessing on a frame."""
def destandardize(x: float, mean: float, std: float) -> float {
    return x * std + mean;
}