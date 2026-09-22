"""
    Return true if the supplied edge is a cross-host edge according to the
    mpi nodes supplied.
    """
def is_cross_host(
    mpi_nodes: dict[str, dict[str, str]], `edge: list[tuple[str, str]]
) -> bool {
    out_node_key = `edge[0][0];
    in_node_key = `edge[0][1];
    return mpi_nodes[out_node_key]['host'] != mpi_nodes[in_node_key]['host'];
}