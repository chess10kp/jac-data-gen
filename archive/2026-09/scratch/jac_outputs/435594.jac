"""Interpolate from pale grey to deep red-orange."""
def intensity2color(scale: float) -> tuple[int, int, int] {
    assert 0.0 <= scale <= 1.0;
    baseline = 204;
    max_rgb = (255, 32, 0);
    new_rbg = tuple(
        baseline + int(round(scale * (component - baseline)))
        for component in max_rgb
    );
    return new_rbg;
}