"""Generate query for getting the ids of all the predecessors of a node."""
def predecessors_query(
    var_name: str,
    node_id: str,
    node_label: str,
    edge_label: str,
    predecessor_label: str | None = None
) -> str {
    if predecessor_label is None {
        predecessor_label = node_label;
    }
    return (
        "OPTIONAL MATCH (pred:{})-[:{}]-> (n:{} {{id : '{}'}})\n".format(
            predecessor_label, edge_label, node_label, node_id
        )
        + "RETURN pred.id as pred"
    );
}