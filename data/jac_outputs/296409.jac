"""offset edge ordering

    Args:
        edge_list (list): list of tuples defining edges

    Returns:
        new_l: offset list of tuples defining edges
    """
def offset(edge_list: list) -> list {
    new_l = [((`edge[0] - 1), (`edge[1] - 1), `edge[-1]) for `edge in edge_list];
    return new_l;
}