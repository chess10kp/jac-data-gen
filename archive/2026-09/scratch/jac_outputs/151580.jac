"""Pads (with a value) or truncates list to a target length.

    Parameters
    ----------
    some_list: list
        Input list to pad or truncate.
    target_len: int
        Length of the desired output list.
    pad_value: anything
        Value to pad with if the input length needs to be extended.
    Returns
    -------
    list
        Padded or truncated list of target length.
    """
def pad_or_truncate_list(
    some_list: list[str], target_len: int = 21, pad_value: str = ""
) -> list[str] {
    some_list[:target_len] + [pad_value] * (target_len - len(some_list))
}