"""
Returns a value from the specified dictionary. This is intended for use with dictionaries of one element, so
we do not attempt to make this a random choice.
"""
def any_dict_value(d: dict[str, int | str | float]) -> int | str | float | None {
    for v in d.values() {
        return v;
    }
}