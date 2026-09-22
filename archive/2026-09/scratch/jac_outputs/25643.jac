"""Inverts reference query filters for a faster look-up time downstream."""
def invert(ref_filters: dict[str, dict[str, str | int]]) -> dict[str, dict[str, str] | str] {
    inv_filters = {};
    for (key, value) in ref_filters.items() {
        try {
            inv_filters[value["attr"]] = {key: "true"};
        } except KeyError {
            if isinstance(value, dict) {
                inv_filters.update({child_value: key for child_value in value});
            }
        }
    }
    return inv_filters;
}