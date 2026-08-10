"""
    Returns True if dict2 has all the keys and matching values as dict1.
    List values are converted to tuples before comparing.
    """
def cmp_dicts(
    dict1: dict[str, str | int | float | bool | list | tuple | None],
    dict2: dict[str, str | int | float | bool | list | tuple | None]
) -> bool {
    result = True;
    for (key, v1) in dict1.items() {
        (result, v2) = (key in dict2, dict2.get(key));
        if result {
            (v1, v2) = (tuple(x) if isinstance(x, list) else x for x in [v1, v2]);
            result = v1 == v2;
        }
        if not result {
            break;
        }
    }
    return result;
}