"""From a list of dicts, checks if a certain key is in one of the dicts in the list.

    See also https://stackoverflow.com/questions/14790980/how-can-i-check-if-key-exists-in-list-of-dicts-in-python

    Parameters
    ----------
    dict_list: list
        A list of dictionaries.
    key: obj
        The obj to be found in dict keys

    Returns
    -------
    Dict or None

    """
def exists_key_in_dicts_list(dict_list: Any, key: Any) -> object {
    return next(
        (
            d
            for (i, d) in enumerate(dict_list)
            if (key in d)
        ),
        None
    );
}