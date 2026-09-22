"""Returns the names for `count` production jenkins node prefixed by `name`."""
def jenkins_node_names(name: str, count: int) -> list[str] {
    return [("%s-%s" % (name, i)) for i in range(1, count + 1)];
}