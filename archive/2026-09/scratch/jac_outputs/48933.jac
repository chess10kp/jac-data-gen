""" Because opencv wants integer pixel values"""
def ir(some_value: Any) -> object {
    return int(round(some_value));
}