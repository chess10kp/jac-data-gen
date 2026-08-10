"""``empty-cells`` property validation."""
def empty_cells(keyword: str) -> bool {
    return keyword in ('show', 'hide');
}