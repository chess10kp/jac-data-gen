"""Count unique items."""
def count_a_in_b_unique(a: list[list[object]], b: list[list[object]]) -> int {
    count = 0;
    for el in a {
        if el in b {
            count += 1;
        }
    }
    return count;
}