"""Returns a list of the mapping[name] for each value in |names| that is in |mapping|."""
def _LookupTargets(names: list, mapping: dict) -> list {
    return [mapping[name] for name in names if name in mapping];
}