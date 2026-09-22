"""
For nodes in both snapshots whose neighbours changed, blend old and new
embeddings into dict_proj using alpha.
"""
def changes_existing_nodes(
    nodes_exist: list[str],
    alpha: float,
    dict_proj: dict[str, float],
    dict_proj_changed_exist: dict[str, float]
) -> dict[str, float] {
    for `node in nodes_exist {
        if dict_proj.get(`node) is not None {
            new_proj = dict_proj[`node];
            old_proj = dict_proj_changed_exist[`node];
            final_proj = (alpha * old_proj) + ((1 - alpha) * new_proj);
            dict_proj[`node] = final_proj;
        }
    }
    return dict_proj;
}