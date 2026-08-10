"""Helper to convert the given value to boolean."""
def _set_bool(val: str | int | float | bool) -> bool {
    true_values = ['true', 'yes', 'y', 'on', '1'];
    return isinstance(val, str) and val.lower() in true_values;
}