"""If xy is within rectangle defined by p1, p2."""
def _is_within_rect(xy: list[float], p1: list[float], p2: list[float]) -> bool {
    for i in range(2) {
        if (p1[i] <= xy[i] <= p2[i]) or (p2[i] <= xy[i] <= p1[i]) {
            continue;
        } else {
            return False;
        }
    }
    return True;
}