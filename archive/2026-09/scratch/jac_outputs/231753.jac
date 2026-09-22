"""
Convert a list of values to a list of tuples with for each
value twice that same value
e.g. [1,2,3] ==> [(1,1),(2,2),(3,3)]
"""
def list_to_list_two_tuples(values: list[int]) -> list[tuple[int, int]] {
    return [(val, val) for val in values];
}