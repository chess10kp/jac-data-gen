"""Get an item from a nested dictionary, or return default if not found."""
def nested_dict_get(
    dictionary: dict[str | int, dict | str | int | float | bool | list],
    *keys: str | int,
    **kargs: dict[str, dict | str | int | float | bool | list | None]
) -> dict | str | int | float | bool | list | None {
    `default: dict | str | int | float | bool | list | None;
    if len(kargs) == 1 and "default" in kargs {
        `default = kargs["default"];
    } elif len(kargs) == 0 {
        `default = None;
    } else {
        raise TypeError('optional argument can only be "default"');
    }
    element: dict[str | int, dict | str | int | float | bool | list] | str | int | float | bool | list = dictionary;
    for k in keys {
        if k in element {
            element = element[k];
        } else {
            return `default;
        }
    }
    return element;
}