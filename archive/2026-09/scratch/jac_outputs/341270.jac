"""Given the indices of the prime, returns a sequence of patterns."""
def transform_back_into_seq(true_indices: dict[int, list[int]]) -> list[int] {
    reversed_indices = {};
    for key in true_indices {
        for val in true_indices[key] {
            reversed_indices[val] = key;
        }
    }
    return [reversed_indices[val] for val in sorted(reversed_indices.keys())];
}