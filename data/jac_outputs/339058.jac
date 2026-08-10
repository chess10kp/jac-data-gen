"""Maps every node to an ID."""
def get_node_map(node_set: set[str | int]) -> dict[str | int, int] {
    nodes = list(node_set);
    nodes.sort();
    node_id_map: dict[str | int, int] = {};
    for (i, n) in enumerate(nodes) {
        node_id_map[n] = i;
    }
    return node_id_map;
}