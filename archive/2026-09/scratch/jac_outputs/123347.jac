"""Return the nested leaf element corresponding to all dictionary keys in branch from element."""
def get_tree_leaf(element: dict | str | int | float | bool | list, branch: list) -> dict | str | int | float | bool | list {
    if isinstance(element, dict) and len(branch) > 0 {
        return get_tree_leaf(element[branch[0]], branch[1:]);
    }
    return element;
}