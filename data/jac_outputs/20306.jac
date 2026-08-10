"""
    Turns a date/time into a long string as needed by midas code.
    """
def revert_datetime_to_long_string(dt: Any) -> object {
    return str(dt).replace("-", "").replace(" ", "").replace("T", "").replace(":", "");
}