"""
       Converts 'something' to boolean. Raises exception for invalid formats
           Possible True  values: 1, True, "1", "TRue", "yes", "y", "t"
           Possible False values: 0, False, None, [], {}, "", "0", "faLse", "no", "n", "f", 0.0, ...
    """
def to_bool_str(value: Any) -> object {
    if (str(value).lower() in ("yes", "y", "true", "t", "1")) {
        return "1";
    }
    if (
        str(value).lower()
        in ("no", "n", "false", "f", "0", "0.0", "", "none", "[]", "{}")
    ) {
        return "0";
    }
    raise Exception(('Invalid value for boolean conversion: ' + str(value)));
}