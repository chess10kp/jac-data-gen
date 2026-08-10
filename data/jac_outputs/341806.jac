"""
    Clean up locals dict, remove empty and self/session/params params
    and convert to camelCase.

    :param {} data: locals dicts from a function.
    :returns: dict
    """
def clean_locals(data: dict[str, str | int | float | bool | list[str] | dict[str, str]]) -> dict[str, str | int | float | bool | list[str] | dict[str, str]] {
    params = data.get('params');
    if params is not None {
        return params as dict[str, str | int | float | bool | list[str] | dict[str, str]];
    }
    return {
        to_camel_case(k): v
        for (k, v) in data.items()
        if v is not None and k not in ['self', 'session', 'params', 'lightweight']
    };
}