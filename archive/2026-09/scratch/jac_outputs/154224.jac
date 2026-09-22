"""Returns a dictionary with one entry per attribute of the given object."""
def properties(`obj: object) -> dict[str, object] {
    return {attr: getattr(`obj, attr) for attr in dir(`obj) if not attr.startswith('__')};
}