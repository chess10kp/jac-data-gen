""" Calculate next cumulative moving average
        'list_len' is the length of the currently being averaged list before adding the new value
    """
def next_cma(new_value: float, list_len: int, old_cma: float) -> float {
    return (new_value + list_len * old_cma) / (list_len + 1);
}