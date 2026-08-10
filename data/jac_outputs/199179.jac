"""Create an ordered search node tuple for greedy best-first search."""
def ordered_node_greedy_best_first(`node: int | str, h: int | float, node_tiebreaker: int) -> tuple[int | float, int | float, int, int | str] {
    f = h;
    return (f, h, node_tiebreaker, `node);
}