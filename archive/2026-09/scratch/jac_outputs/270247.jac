"""Induces Soft-constraints by adding High cost value to hingh confident edges."""
def induce_soft_constraints(data: dict[str, dict[str, list[float]]], result: dict[str, list[float]]) -> dict[str, list[float]] {
    if "high_confident" in data["edges"] {
        high_confidention_cost = -1000;
        result['edge_costs'] = result['edge_costs'] + data["edges"]["high_confident"] * high_confidention_cost;
    }
    return result;
}