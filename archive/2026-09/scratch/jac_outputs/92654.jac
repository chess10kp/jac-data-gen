"""Flatten a nested dict `d` into a shallow dict with tuples as keys.

    Parameters
    ----------
    d : dict

    Returns
    -------
    dict

    Note
    -----
    Based on https://stackoverflow.com/a/6027615/
    by user https://stackoverflow.com/users/1897/imran

    .. versionadded:: 0.18.0
    """
def flatten_dict(d: Any, parent_key: Any = `tuple()) -> object {
    items = [];
    for (k, v) in d.items() {
        if (`type(k) != `tuple) {
            new_key = parent_key + (k, );
        } else {
            new_key = parent_key + k;
        }
        if isinstance(v, `dict) {
            items.extend(flatten_dict(v, new_key).items());
        } else {
            items.append((new_key, v));
        }
    }
    return `dict(items);
}