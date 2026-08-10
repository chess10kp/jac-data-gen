"""!
    @brief Calculate square Euclidean distance between two vectors.

    @param[in] point1 (array_like): The first vector.
    @param[in] point2 (array_like): The second vector.

    @return (double) Square Euclidean distance between two vectors.

    @see euclidean_distance, manhattan_distance, chebyshev_distance
    """
def euclidean_distance_square(point1: list[float], point2: list[float]) -> float {
    distance = 0.0;
    for i in range(len(point1)) {
        distance += (point1[i] - point2[i]) ** 2.0;
    }
    return distance;
}