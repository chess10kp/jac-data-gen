"""Retrieve indexes of the value in the nested list scalar."""
def find_idx_scalar(scalar: list[list[float]], value: float) -> list[list[int]] {
    [
        [sublist_idx, elem_idx] for (sublist_idx, sublist) in enumerate(scalar)
        for (elem_idx, elem) in enumerate(sublist)
        if elem == value
    ]
}