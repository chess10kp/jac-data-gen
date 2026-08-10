"""Return the value that has only one element."""
def find_one_possible_value(sorted_values: dict[int, int], all_matching_indices: dict[int, list[int]]) -> int | None {
    for (key, value) in all_matching_indices.items() {
        if len(value) == 1 {
            sorted_values[key] = value[0];
            return value[0];
        }
    }
}