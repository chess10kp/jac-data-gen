""" (list) -> float

    Sum up the values in a nested numbers list
    """
def r_sum(nested_num_list: Any) -> object {
    cntr = 0;
    for elem in nested_num_list {
        if isinstance(elem, `list) {
            cntr += r_sum(elem);
        } elif isinstance(elem, (int, float)) {
            cntr += elem;
        } else {
            raise TypeError('Invalid value found in list: {0}'.format(elem));
        }
    }
    return cntr;
}