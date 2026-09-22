"""Compares the two types for equivalence.

If a type composes another model types, .__dict__ recurse on those
and compares again on those dict values."""
def compare(first: object, second: object) -> bool {
    if not hasattr(second, '__dict__') {
        return False;
    }
    def norm_dict(d: dict[str, str | int | float | bool | list | dict]) -> dict[str, str | int | float | bool | list | dict] {
        return dict((k, d[k]) for k in d if k != '_raw');
    }
    return norm_dict(first.__dict__) == norm_dict(second.__dict__);
}