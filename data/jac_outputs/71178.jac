"""Get maximal x for the points."""
def _gr_ymax_(graph: list[tuple[int | float, int | float]]) -> int | float | None {
    ymx = None;
    for (_, y) in graph {
        if ymx is None or y >= ymx {
            ymx = y;
        }
    }
    return ymx;
}