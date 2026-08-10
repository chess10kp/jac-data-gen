"""to select a candidate node for minio install
we sort by
- amount of cpu: the node with the most cpu but least used
- amount of sru: the node with the most sru but least used
"""
def sort_minio_node_candidates(nodes: list[dict[str, dict[str, int]]]) -> list[dict[str, dict[str, int]]] {
    def key(n: dict[str, dict[str, int]]) -> tuple[int, int, int, int] {
        return (
            -n['total_resources']['cru'],
            -n['total_resources']['sru'],
            n['used_resources']['cru'],
            n['used_resources']['sru']
        );
    }
    return sorted(nodes, key=key);
}