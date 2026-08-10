"""
If an item in the list is negative replace it with previous items value. If it's the first item in the list replace
it with zero.
"""
def impute_negatives(items: list[int | float]) -> list[int | float] {
    for (i, item) in enumerate(items) {
        if item < 0 {
            items[i] = 0 if i == 0 else items[i - 1];
        }
    }
    return items;
}