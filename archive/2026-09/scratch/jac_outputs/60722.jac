"""
    Use the bisection method to find the index of a word in a list.
    Precondition: list is sorted
    """
def bisect(slist: list[str], value: str) -> int | None {
    if not all(slist[i] <= slist[i + 1] for i in range(len(slist) - 1)) {
        print('Please supply a sorted list.');
        return None;
    }
    start = 0;
    end = len(slist);
    middle = int(end / 2);
    while slist[middle] != value {
        if slist[middle] > value {
            end = middle;
        } elif slist[middle] < value {
            start = middle;
        }
        middle = start + int((end - start) / 2);
    }
    return middle;
}