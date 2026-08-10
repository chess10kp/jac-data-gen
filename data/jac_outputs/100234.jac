"""Binary search in an ordered list. Complexity: O(log n)."""
def ordered_binary_search(ordered_list: list[int], item: int) -> bool | None {
    first = 0;
    last = len(ordered_list) - 1;
    found = False;
    while first <= last and not found {
        midpoint = (first + last) // 2;
        if ordered_list[midpoint] == item {
            found = True;
        } elif item < ordered_list[midpoint] {
            last = midpoint - 1;
        } else {
            first = midpoint + 1;
        }
        return found;
    }
}