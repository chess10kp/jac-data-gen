"""Returns a string made from given params."""
def make_edge_id(source_node_index: int, first_char: str) -> str {
    return "{}::{}".format(source_node_index, first_char);
}