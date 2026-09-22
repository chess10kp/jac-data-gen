"""
    Returns a 0-based list of integers specifying which occurrence,
    i.e. enumerated duplicate, each list item is.

    For example, if `lst` = [ 'A','B','C','C','A'] then the
    returned list will be   [  0 , 0 , 0 , 1 , 1 ].  This is useful
    when working with `DataSet` objects that have `collisionAction`
    set to "keepseparate".
    """
def compute_occurrence_indices(lst: list[str | int]) -> list[int] {
    lookup: dict[str | int, int] = {};
    ret: list[int] = [];
    for x in lst {
        if x not in lookup {
            lookup[x] = 0;
        } else {
            lookup[x] += 1;
        }
        ret.append(lookup[x]);
    }
    return ret;
}