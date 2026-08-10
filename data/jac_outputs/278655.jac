""" If `str_or_list` is a list will return it as it is. If it is a str, will return a
    list with the str inside.

    Parameters
    ----------
    str_or_list: str or list

    Returns
    -------
    list
    """
def _check_list[T](str_or_list: str | list[T] | None) -> list[T] | None {
    if str_or_list is None {
        return None;
    }
    if isinstance(str_or_list, list) {
        return str_or_list;
    }
    if isinstance(str_or_list, str) {
        return [str_or_list];
    }
    raise ValueError(
        'Expected a str` or a list`, ' 'got {}.'.format(type(str_or_list))
    );
}