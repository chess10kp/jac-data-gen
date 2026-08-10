"""Return a formatted string.

    :param data: a list of dicts
    :rtype: a string formatted to {a:b, c:d}, {e:f, g:h}
    """
def format_long_dict_list(data: Any) -> object {
    newdata = [
        str({str(key): str(value) for (key, value) in d.iteritems()}) for d in data
    ];
    return (',\n'.join(newdata) + '\n');
}