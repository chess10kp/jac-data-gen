"""Checks if the parameter is a valid integer value and greater than zero."""
def is_valid_int_greater_zero_param(param: int | str | float | bool | bytes | None, required: bool = True) -> bool {
    if param is None and not required {
        return True;
    } elif param is None {
        return False;
    }
    try {
        param = int(param);
        if param <= 0 {
            return False;
        }
    } except (TypeError, ValueError) {
        return False;
    }
    return True;
}