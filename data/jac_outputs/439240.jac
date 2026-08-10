"""Construct a dict with a {`key`: `val`} structure if given `val` is not a dict`, or copy `val` otherwise."""
def as_dict(val: dict[str, str] | str, key: str) -> dict[str, str] {
    return val.copy() if isinstance(val, dict) else {key: val};
}