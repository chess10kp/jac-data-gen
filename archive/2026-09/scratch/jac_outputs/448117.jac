"""
Given a param string and a dict of values, returns a flat dict of keyed, enumerated params.
Each dict in the values list must pertain to a single item and its data points.
"""
def enumerate_keyed_param(
    param: str,
    values: list[dict[str, str | int]] | dict[str, str | int] | tuple | set
) -> dict[str, str | int] {
    if not values {
        return {};
    }
    if not param.endswith('.') {
        param += '.';
    }
    if not isinstance(values, (list, tuple, set)) {
        values = [values];
    }
    for val in values {
        if not isinstance(val, dict) {
            raise ValueError(
                "Non-dict value detected. "
                "`values` must be a list, tuple, or set; containing only dicts."
            );
        }
    }
    params: dict[str, str | int] = {};
    for (idx, val_dict) in enumerate(values) {
        params.update(
            {
                '{param}{idx}.{key}'.format(param=param, idx=idx + 1, key=k): v
                for (k, v) in val_dict.items()
            }
        );
    }
    return params;
}