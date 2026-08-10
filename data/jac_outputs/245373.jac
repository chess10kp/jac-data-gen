"""Converts a string to a boolean.

    Raises:
        ValueError: If it cannot be converted.
    """
def str2bool(v: bool | str) -> bool {
    if isinstance(v, bool) {
        return v;
    } elif isinstance(v, str) {
        v_low = v.lower();
        if v_low in ("yes", "true", "t", "y", "1", "1.0") {
            return True;
        } elif v_low in ("no", "false", "f", "n", "0", "0.0") {
            return False;
        }
    }
    raise ValueError(f"{v} is not convertible to boolean!");
}