"""Helper function to get right sibling -- no guarantee it exists in tree."""
def get_neighbor_pos(pos: list[int]) -> list[int] {
    neighbor = list(pos);
    neighbor[-1] += 1;
    return neighbor;
}