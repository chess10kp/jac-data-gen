"""Find the parent node index in a pre-order traversal list."""
def find_parent(lst: list[int], i: int, dist: int) -> int {
    while i >= 0 {
        if lst[i] < dist {
            break;
        }
        i -= 1;
    }
    return i;
}