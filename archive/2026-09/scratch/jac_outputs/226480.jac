"""A default validator, return False when value is None or an empty string. """
def _default_validator(value: object) -> bool {
    if not value or not str(value).strip() {
        return False;
    }
    return True;
}