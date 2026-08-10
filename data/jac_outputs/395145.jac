"""
    Array must be ordered!
    """
def ordered_sequential_search(array: list[int], element: int) -> bool {
    pos = 0;
    found = False;
    stopped = False;
    while pos < len(array) and not found and not stopped {
        if array[pos] == element {
            found = True;
        } elif array[pos] > element {
            stopped = True;
        } else {
            pos += 1;
        }
    }
    return found;
}