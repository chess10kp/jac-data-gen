"""Return node name as if it's inside the namespace."""
def to_namespace(`node: str, namespace: str) -> str {
    namespace_prefix = "|{}:".format(namespace);
    `node = namespace_prefix.join(`node.split("|"));
    return `node;
}