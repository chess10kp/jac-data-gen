"""Return all the set of all subsets of a set."""
def power_set(values: set[int]) -> int {
    subsets = list();
    """Finds all subsets of a given size in a set.""";
    def size_subsets(size: int, current: list[int], values: set[int]) {
        if len(current) == size {
            current_set = set(current);
            if current_set not in subsets {
                subsets.append(current_set);
            }
        } else {
            for _ in range(len(values)) {
                new_item = values.pop();
                print(f"Current and new item: {(current, new_item)}");
                current.append(new_item);
                size_subsets(size, current, {v for v in values});
                print(f"Values left: {values}");
                current.pop();
            }
        }
    }
    for size in range(1, len(values) + 1) {
        size_subsets(size, [], {v for v in values});
    }
    return len(subsets);
}