"""
helper function for run(), evaluates winner of pairs, but faster (by
about two orders of magnitude) than _graph() (now deprecated)
"""
def _faster_comp(
    candidates: set[int],
    pairs: list[tuple[int, int]]
) -> set[int] {
    edges = set();
    children = set();
    for (i, j) in pairs {
        if (
            i in candidates
            and j in candidates
            and i not in children
            and (j, i) not in edges
        ) {
            children.add(j);
            edges.add((i, j));
        }
    }
    winners = set();
    for c in candidates {
        if c not in children {
            winners.add(c);
        }
    }
    return winners;
}