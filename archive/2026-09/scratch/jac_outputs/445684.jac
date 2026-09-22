""" Checks if given value is boolean """
def is_valid_boolean(val: bool | int | str | float | None) -> bool {
    values = [True, False];
    return val in values;
}