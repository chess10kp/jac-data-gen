"""Sort sons from node.sons.items()"""
def sort_sons(items: Any) -> object {
    return sorted(items, key=lambda (it: Any) { it[1].data['rank']; });
}