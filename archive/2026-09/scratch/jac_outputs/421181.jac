"""Validate yes-no question."""
def validate_yes_no(value: bool | str | None) -> bool | str | None {
    if isinstance(value, bool) {
        return value;
    }
    if value is None or value == "<ask>" {
        return value;
    }
    check_value = value.strip().lower();
    if check_value in ("", "y", "yes", "t", "true", "1") {
        return True;
    }
    if check_value in ("n", "no", "f", "false", "0") {
        return False;
    }
    return None;
}