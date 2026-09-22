"""Creates node for the GML file

    :param node_id: The id of the node
    """
def create_node_str(node_id: Any) -> object {
    node_str = "\tnode\n\t[\n\t\tid " + str(node_id) + "\n\t]\n";
    return node_str;
}