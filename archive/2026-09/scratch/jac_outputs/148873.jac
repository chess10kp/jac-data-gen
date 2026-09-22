"""Returns a default value for a dict key if it was not found, otherwise returns the dict item."""
def _get_dict_value(src: dict[object, object], value: object, `default: object) -> object {
    if value in src {
        return src[value];
    }
    return `default;
}