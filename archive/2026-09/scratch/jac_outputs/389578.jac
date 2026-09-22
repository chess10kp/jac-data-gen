"""
    2 bytes: seconds: 0 to 59
    """
def clock_sec(value: Any) -> object {
    return {'seconds': value};
}