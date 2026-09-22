"""
    Makes sure the value is a integer that represents a boolean, otherwise
    raises AssertionError

    :param name: Argument name
    :param value: Value
    :return: Value as integer
    """
def assert_bool(name: str, value: str) -> int {
    if (int(value) not in [0, 1]) {
        raise AssertionError(
            "Expected 0 or 1 for {}, but got `{}`".format(name, value)
        );
    }
    return (int(value) == 1);
}