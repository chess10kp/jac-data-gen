"""
    Return the repository file for node if it has one. Otherwise return node
    """
def rfile(`node: str | dict[str, str] | int) -> str | dict[str, str] | int {
    if hasattr(`node, "rfile") {
        return getattr(`node, "rfile")();
    }
    return `node;
}