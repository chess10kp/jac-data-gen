"""Safely set data attribute or unset if user set it to a special value."""
def _set(data: dict[str, str | int | list[str]], name: str, value: str | int | list[str] | None, unset_value: str | int | None = None) -> bool {
    if value is None {
        return False;
    }
    if unset_value is not None and value == unset_value {
        data.pop(name, None);
    } elif value in ('-', ['-']) {
        data.pop(name, None);
    } else {
        data[name] = value;
    }
    return True;
}