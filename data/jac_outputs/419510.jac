"""
    Given a unsorted list of integers other comparable types,
    it rearrange the integers in natural order in place in an
    descending order.
    Example: Input:  [8,5,3,1,7,6,0,9,4,2,5]
             Output: [9,8,7,6,5,5,4,3,2,1,0]
    """
def insertion_sort_descending(dList: list[int]) -> list[int] {
    n = len(dList);
    for i in range(n - 2, -1, -1) {
        j = i;
        at_hand = dList[i];
        while j < n - 1 and at_hand < dList[j + 1] {
            dList[j] = dList[j + 1];
            j += 1;
        }
        dList[j] = at_hand;
    }
    return dList;
}