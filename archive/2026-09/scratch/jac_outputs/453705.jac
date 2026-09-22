"""Order nodes by their topological order."""
def ts(nodes: list[str], topo_order: list[str]) -> list[str] {
    node_set = set(nodes);
    [n for n in topo_order if n in node_set]
}