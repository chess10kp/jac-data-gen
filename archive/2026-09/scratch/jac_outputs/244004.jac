"""
    Generate row indices within neighbor_range of center, clamped to [0, length).

    Examples:
    1. center: 1, length: 2, neighbor_range: 1 -> [0, 1, 2]
    2. center: 1, length: 1, neighbor_range: 1 -> [0, 1]
    3. center: 1, length: 4, neighbor_range: 2 -> [0, 1, 2, 3]
    """
def get_row_indices(center: int, length: int, neighbor_range: int) -> list[int] {
    return [
        x
        for x in range(max(0, center - neighbor_range), min(length, center + 1 + neighbor_range))
    ];
}