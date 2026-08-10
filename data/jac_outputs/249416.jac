"""Return the Levenshtein distance between two strings."""
def min_edit(s1: str, s2: str) -> int {
    if len(s1) > len(s2) {
        (s1, s2) = (s2, s1);
    }
    distances: list[int] = [i for i in range(len(s1) + 1)];
    for (index2, char2) in enumerate(s2) {
        new_distances = [index2 + 1];
        for (index1, char1) in enumerate(s1) {
            if char1 == char2 {
                new_distances.append(distances[index1]);
            } else {
                new_distances.append(
                    1 + min(distances[index1], distances[index1 + 1], new_distances[-1])
                );
            }
        }
        distances = new_distances;
    }
    return distances[-1];
}