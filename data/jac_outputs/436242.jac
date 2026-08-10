"""Calculate texture similarity using histogram intersection."""
def _calculate_texture_sim(ri: dict[str, list[float]], rj: dict[str, list[float]]) -> float {
    return sum([min(a, b) for (a, b) in zip(ri["texture_hist"], rj["texture_hist"])]);
}