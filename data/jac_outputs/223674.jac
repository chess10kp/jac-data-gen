"""Scale the potential by scaling factor."""
def scale(pot: dict[tuple[float], float], scale_factor: float) -> dict[tuple[float], float] {
    return {idx: val * scale_factor for (idx, val) in pot.items()};
}