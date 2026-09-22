"""Determine the correct levels argument to groupby."""
def _determine_levels(index: tuple | list | int | str) -> list[int] | int {
    if isinstance(index, (tuple, list)) and len(index) > 1 {
        return list(range(len(index)));
    }
    return 0;
}