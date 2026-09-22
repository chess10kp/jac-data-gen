"""Return a pair with the edge's endpoints (the nodes it connects)."""
def endpoints(`edge: list[int]) -> tuple[int, ...] {
    if len(`edge) == 2 {
        return tuple(`edge);
    } else {
        return tuple(`edge) + tuple(`edge);
    }
}