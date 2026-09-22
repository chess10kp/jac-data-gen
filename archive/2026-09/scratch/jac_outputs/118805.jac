"""Unescapes any special characters in an ontology node name."""
def unescape_node_name(node_name: str) -> str {
    return node_name.replace(r"\|", r"|").replace(r"\.", r".");
}