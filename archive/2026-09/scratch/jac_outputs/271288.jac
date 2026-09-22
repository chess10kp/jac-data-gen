"""Return single value if list len is 1."""
def _delist(val: list | set | str | int | float | bool | dict | None) -> object {
    return (val as list | set)[0] if type(val) in (list, set) and len(val as list | set) == 1 else val;
}