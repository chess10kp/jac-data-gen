"""
    Apply dot-separated path overrides to a nested dict/list structure.

    Mutates the passed-in dictionary.
    """
def do_overrides(
    data: dict[str, int | str | list[int] | dict[str, int | str | list[int] | dict[str, int | str]]],
    overrides: dict[str, int | str]
) -> dict[str, int | str | list[int] | dict[str, int | str | list[int] | dict[str, int | str]]] {
    for (path, value) in overrides.items() {
        parts = path.split(".");
        last_part: str | int = parts[-1];
        first_parts = parts[:-1];
        item: dict[str, int | str | list[int] | dict[str, int | str | list[int] | dict[str, int | str]]] | list[int] = data;
        for part in first_parts {
            if isinstance(item, list) {
                part = int(part);
            }
            try {
                item = item[part];
            } except KeyError {
                raise ValueError("Invalid key: {0} in {1}".format(part, path));
            }
        }
        if isinstance(item, list) {
            if last_part == "append" {
                item.append(value);
                continue;
            } else {
                last_part = int(last_part);
            }
        }
        item[last_part] = value;
    }
    return data;
}