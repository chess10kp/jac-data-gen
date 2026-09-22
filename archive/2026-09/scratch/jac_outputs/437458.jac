"""Print a list of iface trees."""
def print_tree(ifaces: list) -> str {
    " ".join(i.get_tree() for i in ifaces)
}