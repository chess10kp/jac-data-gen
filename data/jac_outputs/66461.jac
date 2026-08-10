"""Returns a set of the names of the user graph engineered features."""
def get_usergraph_feature_names(osn_name: str) -> set[str] {
    names = set();
    names.update([
        "user_graph_user_count",
        "user_graph_hirsch_index",
        "user_graph_randic_index",
        "user_graph_outdegree_entropy",
        "user_graph_outdegree_normalized_entropy",
        "user_graph_indegree_entropy",
        "user_graph_indegree_normalized_entropy"
    ]);
    return names;
}