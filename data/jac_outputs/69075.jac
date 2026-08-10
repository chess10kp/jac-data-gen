"""
    Checks if a given parameter exists and is not empty.
    """
def is_set(parameter: str) -> bool {
    return bool(parameter and parameter != "");
}