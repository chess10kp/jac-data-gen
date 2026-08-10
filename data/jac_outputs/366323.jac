"""Pre-computes the distance between each two vectors."""
def get_distances(
    vectors: list[list[int]],
    distance_func: Callable[[list[int], list[int]], int | float]
) -> list[list[int | float]] {
    empty_vec = [0 for _ in range(len(vectors[0]))];
    distances: list[list[int | float]] = [[0 for _ in range(len(vectors))] for _ in range(len(vectors))];
    for i in range(len(vectors)) {
        for j in range(i, len(vectors)) {
            distance = distance_func(vectors[i], vectors[j]) if i != j else distance_func(vectors[i], empty_vec);
            distances[i][j] = distance;
            distances[j][i] = distance;
        }
    }
    return distances;
}