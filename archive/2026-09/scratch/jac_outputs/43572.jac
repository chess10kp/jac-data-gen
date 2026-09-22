"""Get the first defined key in data."""
def get_first_defined(
    data: dict[object, object], keys: list[object], default_value: object | None = None
) -> object {
    for key in keys {
        if key in data {
            return data[key];
        }
    }
    return default_value;
}