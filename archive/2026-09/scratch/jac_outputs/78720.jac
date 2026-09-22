"""Return parameter value as boolean."""
def _validate_bool(value: bool | int | str) -> bool | int {
    if value in [True, False] {
        return value as bool | int;
    }
    try {
        if str(value).lower() == 'true' {
            return True;
        }
        if str(value).lower() == 'false' {
            return False;
        }
        raise TypeError("'{}' is not a valid bool".format(value));
    } except UnicodeEncodeError {
        raise TypeError("'{}' is not a valid bool".format(value));
    }
}