"""

    Parameters
    ----------
    list_values : list
        List with different values

    Returns
    -------
    list_no_nones : list
        List with extract of list_values. No more None values included
    """
def erase_none_val_from_list(list_values: Any) -> object {
    list_no_nones = [];
    for val in list_values {
        if (val is not None) {
            list_no_nones.append(val);
        }
    }
    return list_no_nones;
}