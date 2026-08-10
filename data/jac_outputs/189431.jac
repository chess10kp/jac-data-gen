"""Return a possibly deeply buried {key, value} with all parent keys.

    Given:

        keys = ['a', 'b']
        d = {'a': {'b': 1, 'c': 3}, 'b': 4}

    returns:

        {'a': {'b': 1}}

    """
def find_item(keys: list[str], d: dict[str, int | dict[str, int]], create: bool = False) -> dict[str, int | dict | None] {
    fallback: dict[str, int | dict[str, int]] | None = {} if create else None;
    value = d.get(keys[0], fallback);
    if len(keys) > 1 and type(value) is dict {
        return {keys[0]: find_item(keys[1:], value as dict[str, int | dict[str, int]], create)};
    }
    return {keys[0]: value};
}