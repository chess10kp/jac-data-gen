"""Acumulate the best possible donation sum at any point in the array."""
def get_donations(values: list[int]) -> int {
    best_values = {0: values[0], 1: values[1], 2: values[0] + values[2]};
    for idx in range(3, len(values)) {
        current = values[idx] + max(best_values[idx - 3], best_values[idx - 2]);
        best_values[idx] = current;
    }
    return best_values[len(values) - 1];
}