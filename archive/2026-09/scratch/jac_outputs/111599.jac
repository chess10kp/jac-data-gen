"""
    Helper method to remap entries in a list or keys in a dictionary
    based on an input map, used to translate symbols to properties
    and vice-versa

    Args:
        obj ([] or {} or set) a list of properties or property-keyed
            dictionary to be remapped using symbols.
        mapping ({}): dictionary of values to remap

    Returns:
        remapped list of items or item-keyed dictionary
    """
def remap(`obj: Any, mapping: Any) -> object {
    if isinstance(`obj, `dict) {
        new = {
            (mapping.get(in_key) or in_key): `obj.get(in_key) for in_key in `obj.keys()
        };
    } else {
        new = [(mapping.get(in_item) or in_item) for in_item in `obj];
        if isinstance(`obj, `set) {
            new = `set(new);
        }
    }
    return new;
}