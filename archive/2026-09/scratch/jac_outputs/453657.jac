"""A more conventional recursive function (not a recursive generator)."""
def count_paths_recursive(graph: dict[int, list[int]], node_val: int, target: int) -> int {
    if node_val >= target {
        return 1;
    }
    total = 0;
    for next_node in graph[node_val] {
        total += count_paths_recursive(graph, next_node, target);
    }
    return total;
}