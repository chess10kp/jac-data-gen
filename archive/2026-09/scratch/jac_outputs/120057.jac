"""
Converts integer to one_hot dictionary to a one_hot to integer dictionary.

Arguments
---------
one_hot_ndarray : A numpy.ndarray
    Contains one-hot format of class labels.

Returns
-------
tuple_to_int_dict : dictionary
    keys are tuples with one-hot format and values are integer class labels.
"""
def one_hot_2_label(int_to_vector_dict: dict[int, list[int]]) -> dict[tuple[int, ...], int] {
    return {tuple(val): key for (key, val) in int_to_vector_dict.items()};
}