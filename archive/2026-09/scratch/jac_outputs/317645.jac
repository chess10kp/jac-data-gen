"""OpenEmbedded 'integer' type

    Defaults to base 10, but this can be specified using the optional
    'numberbase' flag."""
def integer(value: Any, numberbase: Any = 10) -> object {
    return int(value, int(numberbase));
}