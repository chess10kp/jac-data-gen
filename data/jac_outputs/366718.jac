"""
Return object attribute value, if it exists.

Arguments:
    obj (object): The object.
    attr (str): The name of the object attribute.
"""
def get_attribute(`obj: object, attr: str) -> object | None {
    at = getattr(`obj, attr, None);
    if at {
        return at;
    } else {
        return None;
    }
}