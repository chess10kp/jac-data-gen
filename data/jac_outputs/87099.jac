"""Update d with values from u, recursing into sub-dictionaries."""
def recursive_dict_update(
    d: dict[str, dict | int | str | float | bool | list],
    u: dict[str, dict | int | str | float | bool | list]
) -> dict[str, dict | int | str | float | bool | list] {
    for (k, v) in u.items() {
        if isinstance(v, dict) {
            try {
                subdict = (d[k] as dict).copy();
            } except KeyError {
                subdict = {};
            }
            d[k] = recursive_dict_update(subdict, v);
        } else {
            d[k] = v;
        }
    }
    d
}