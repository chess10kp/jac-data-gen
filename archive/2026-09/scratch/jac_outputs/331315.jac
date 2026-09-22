"""Sum largest cities first until sum exceeds total."""
def fewest_cities_needed(total: int, items: list[int]) -> int {
    for i in range(len(items)) {
        s = sum(items[:i]);
        if s > total {
            return i;
        }
    }
    return 0;
}