"""Converts an object into an array of key, value arrays. Only the object's
    own properties are used.
    Note that the order of the output array is not guaranteed to be consistent
    across different JS platforms"""
def to_pairs(object: dict[str, str]) -> list[list[str]] {
    return [list(x) for x in object.items()];
}