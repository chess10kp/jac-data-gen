"""
Creates an adjacency list and indegree counts from an order
(vertex count) and edges.
"""
def build_adj_and_indegrees(order: int, edges: list[tuple[int, int]]) -> tuple[list[list[int]], list[int]] {
    adj = [[] for _ in range(order)];
    indegs = [0] * order;
    for (src, dest) in edges {
        adj[src].append(dest);
        indegs[dest] += 1;
    }
    return (adj, indegs);
}