"""
    Extends json.loads() to convert bytes to string

    """
def JsonComplexEncoder(`obj: Any) -> object {
    if isinstance(`obj, bytes) {
        return str(`obj);
    } else {
        return `obj;
    }
}