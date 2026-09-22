""" Checks whether the node types of the inputs match.
        :param node_a: First node.
        :param node_b: Second node.
        :return: True if the object types of the nodes match, False otherwise.
        :raise TypeError: When at least one of the inputs is not a dictionary
                          or does not have a 'node' attribute.
        :raise KeyError: When at least one of the inputs is a dictionary,
                         but does not have a 'node' key.
    """
def type_match(node_a: dict[str, object], node_b: dict[str, object]) -> bool {
    return isinstance(node_a['node'], type(node_b['node']));
}