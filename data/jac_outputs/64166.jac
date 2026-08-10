"""returns {frozesent((par_name, edge1, edge2, ..)): index}"""
def _get_keyed_rule_indices(rules: list[dict[str, object]]) -> dict[frozenset[str], int] {
    new = {};
    for (i, rule) in enumerate(rules) {
        edges = rule.get("edges", rule.get("edge", None)) or [];
        edge_list = [edges as str] if type(edges) == str else edges as list[str];
        par_name = rule["par_name"] as str;
        key = frozenset([par_name] + edge_list);
        new[key] = i;
    }
    return new;
}