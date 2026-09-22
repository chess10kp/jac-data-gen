"""
    This functions gets the source node in the route and return which node is it (node1 ot node2 in the channel)
    :param src: src node in the route
    :param edge_data: dictionary containing the edge's attributes.
    :return: the order of the nodes in the money transformation
    """
def get_nodes_ordered_balance_keys(src: Any, edge_data: Any) -> object {
    if (edge_data['node1_pub'] == src) {
        return ('node1_balance', 'node2_balance');
    }
    return ('node2_balance', 'node1_balance');
}