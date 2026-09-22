"""Turn a list of edges into a list of verticies."""
def edgesToVerts(s: list[tuple[int, int]]) -> set[int] {
    o = set();
    for e in s {
        o.add(e[0]);
        o.add(e[1]);
    }
    return o;
}