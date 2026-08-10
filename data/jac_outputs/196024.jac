"""
    Merges any number of dictionaries together, and returns a single dictionary

    Usage::

        >>> util.merge_dict({"foo": "bar"}, {1: 2}, {"Tx": "erpa"})
        {1: 2, 'foo': 'bar', 'Tx': 'erpa'}
    """
def merge_dict(data: Any, *`override: Any) -> object {
    result = {};
    for current_dict in ((data, ) + `override) {
        result.update(current_dict);
    }
    return result;
}