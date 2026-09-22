"""Convert a string to bool; falsey for "0", "n", "no", and "false"."""
def bool_converter(value: str) -> bool {
    if value.lower() in ("n", "0", "no", "false") {
        return False;
    }
    return bool(value);
}