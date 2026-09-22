"""
    Checks to see if the type of the value is a valid type for
    placing in the dht.
    """
def check_dht_value_type(value: int | float | bool | str | bytes | list[int] | dict[str, int] | None) -> bool {
    typeset = [int, float, bool, str, bytes];
    return (`type(value) in typeset);
}