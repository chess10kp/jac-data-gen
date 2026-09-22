"""Return a dictionary of lists of units grouped by type."""
def group_by_types(units: list[object]) -> dict[type, list[object]] {
    groups = {i.__class__: [] for i in units};
    for i in units {
        groups[i.__class__].append(i);
    }
    return groups;
}