glob TRUTHY_STRINGS = {
    't': True,
    'true': True,
    'y': True,
    'yes': True,
    '1': True
};

"""Returns True if the passed val is T, True, Y, Yes, 1, or boolean True.
    Returns False if the passed val is boolean False or a string that is not T, True, Y, Yes, or 1, or an integer that is not 1.
    Returns the passed val otherwise. Ignores case."""
def istruthy(val: bool | str | int | float | dict | list | None) -> bool | str | int | float | dict | list | None {
    if not val {
        return val;
    } elif isinstance(val, bool) {
        return val;
    } elif isinstance(val, str) {
        return TRUTHY_STRINGS.get(val.strip().lower(), False);
    } elif isinstance(val, int) {
        return 1 if val == 1 else False;
    } else {
        return val;
    }
}