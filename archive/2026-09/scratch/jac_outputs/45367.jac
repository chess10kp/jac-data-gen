"""How many edges would be needed to make v a clique."""
def count_fillin(graph: dict[int, list[int]], nodes: list[int]) -> float {
    count = 0;
    for v1 in nodes {
        for v2 in nodes {
            if v1 != v2 and v2 not in graph[v1] {
                count += 1;
            }
        }
    }
    return count / 2;
}