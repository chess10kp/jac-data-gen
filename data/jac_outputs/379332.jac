"""Returns the center of the given set of 2d coords as a 2-ple."""
def getCenter(coords: list[float]) -> tuple[float, float] {
    xs = [c for (i, c) in enumerate(coords) if i % 2 == 0];
    ys = [c for (i, c) in enumerate(coords) if i % 2 == 1];
    cx = sum(xs) / float(len(xs));
    cy = sum(ys) / float(len(ys));
    return (cx, cy);
}