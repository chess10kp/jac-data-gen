"""
    "Invert" a dictionary of dictionaries passed in i.e. swap inner & outer keys
    e.g. {"a":{"x":1,"y":2},"b":{"x":3,"y":4}} becomes {"x":{"a":1,"b":3},"y":{"a":2,"b":4}}
    """
def invert(x: dict[str, dict[str, int]]) -> dict[str, dict[str, int]] {
    inv = {};
    for k in list(list(x.values())[0].keys()) {
        inv[k] = {outer: inner[k] for (outer, inner) in x.items()};
    }
    return inv;
}