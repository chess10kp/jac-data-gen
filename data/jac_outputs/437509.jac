"""count the number of swaps required to transform array1 into array2"""
def swap_count(list1: list, list2: list) -> float {
    L = list(list2);
    swaps = 0;
    for element in list(list1) {
        ind = L.index(element);
        L.pop(ind);
        swaps += ind;
    }
    return swaps;
}