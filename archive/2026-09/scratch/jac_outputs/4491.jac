"""Returns living neighbors around the cell."""
def get_living_neighbors(i: int, j: int, generation: list[list[int]]) -> int {
    living_neighbors = 0;
    neighbors = [
        (i - 1, j),
        (i + 1, j),
        (i, j - 1),
        (i, j + 1),
        (i - 1, j + 1),
        (i - 1, j - 1),
        (i + 1, j + 1),
        (i + 1, j - 1)
    ];
    for (k, l) in neighbors {
        if 0 <= k < len(generation) and 0 <= l < len(generation[0]) {
            if generation[k][l] == 1 {
                living_neighbors += 1;
            }
        }
    }
    return living_neighbors;
}