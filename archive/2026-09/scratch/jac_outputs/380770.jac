"""Calculate the sum of histogram intersection of texture."""
def _sim_texture(r1: dict[str, list[float]], r2: dict[str, list[float]]) -> float {
    return sum([min(a, b) for (a, b) in zip(r1["hist_t"], r2["hist_t"])]);
}