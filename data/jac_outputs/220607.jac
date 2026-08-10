"""
    Convert pair names to usable format

    Args:
        string_pairs: str
            Comma seperated node pairs in format "node1-node2"

    Returns:
        [tuple]:
            List of tuples with node pair names
    """
def convert_pairs(string_pairs: Any) -> object {
    tuple_pairs = string_pairs;
    if (`type(string_pairs) == str) {
        pairs = string_pairs.replace(" ", "").split(",");
        tuple_pairs = [`tuple(pair.split("-")) for pair in pairs];
    }
    return tuple_pairs;
}