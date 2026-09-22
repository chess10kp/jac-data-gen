"""Return a boolean indicating whether given items are in sorted order.
    Running time: O(n) because we are using a loop to traverse through each item in the list
    Memory usage: O(1) because we aren't creating any additional data structures in the function"""
def is_sorted(items: list[int | str | float]) -> bool {
    for (current, next_item) in zip(items, items[1:]) {
        if next_item < current {
            return False;
        }
    }
    return True;
}