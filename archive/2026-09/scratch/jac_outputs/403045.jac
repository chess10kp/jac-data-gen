"""
    Return the number for which the second occurrence has a smaller index
    than the second occurrence of the other number does. If there are no
    such elements, return -1.
    """
def find_first_duplicate(arr: Any) -> object {
    if (len(arr) == len(`set(arr))) {
        return -1;
    }
    ind_set = `set();
    for elem in arr {
        if (elem in ind_set) {
            return elem;
        } else {
            ind_set.add(elem);
        }
    }
}