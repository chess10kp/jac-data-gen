"""Check if an edge `e` is in a face `f` (adjacent vertices, including wrap-around)."""
def has_edge(e: tuple[int, int], f: tuple[int, ...]) -> bool {
    for pair in zip(f, (f[1:] + (f[0],))) {
        if e == pair or e == pair[::-1] {
            return True;
        }
    }
    return False;
}