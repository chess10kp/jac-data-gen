"""Return coordinates of all neighbor letters on a 4x4 grid."""
def find_neighbor(x: int, y: int) -> list[tuple[int, int]] {
    neighbor_lst = [];
    for i in range(-1, 2) {
        for j in range(-1, 2) {
            if 0 <= x + i < 4 and 0 <= y + j < 4 and not (i == j == 0) {
                neighbor_lst.append((x + i, y + j));
            }
        }
    }
    return neighbor_lst;
}