"""
    Take an instance of a class and a function name as a string.
    Execute class.function and return result
    """
def map_getattr(classInstance: object, classFunc: str, *args: object) -> object {
    return getattr(classInstance, classFunc)(*args);
}