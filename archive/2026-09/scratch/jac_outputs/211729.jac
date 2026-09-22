"""Return a list of nodes (optionally filtered by type) ordered by the
original document order (i.e. the left to right, top to bottom reading
order of English text)."""
def walk_tree(`root: object, *node_types: `type) -> list[object] {
    ordered_nodes: list[object] = [];
    def recurse(`node: object) {
        if not node_types or isinstance(`node, node_types as tuple[`type, ...]) {
            ordered_nodes.append(`node);
        }
        for child in getattr(`node, 'contents', []) {
            recurse(child);
        }
    }
    recurse(`root);
    return ordered_nodes;
}