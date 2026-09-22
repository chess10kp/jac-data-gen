"""Handle converter type "default"."""
def convert_default(*args: int | str | float | bool, **kwargs: int | str | float | bool) -> dict[str, str] {
    schema = {'type': 'string'};
    return schema;
}