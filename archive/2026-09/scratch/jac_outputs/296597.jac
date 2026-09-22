"""Compares two dictionaries to see if they are equal."""
def is_dict_equal(
    d1: dict[str, object],
    d2: dict[str, object],
    keys: list[str] | None = None,
    ignore_none_values: bool = True
) -> bool {
    if keys or ignore_none_values {
        d1 = {
            k: v
            for (k, v) in d1.items()
            if (keys is None or k in keys) and (v is not None or not ignore_none_values)
        };
        d2 = {
            k: v
            for (k, v) in d2.items()
            if (keys is None or k in keys) and (v is not None or not ignore_none_values)
        };
    }
    return d1 == d2;
}