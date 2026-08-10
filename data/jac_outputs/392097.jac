"""
Return the value for a udev key.

The `key` parameter is a lower case text joined by dots. For
example, 'e.id_bus' will represent the key for
`udev_info['E']['ID_BUS']`.
"""
def _udev(udev_info: dict[str, object], key: str) -> dict[str, object] | str | int | float | bool {
    (k, _, r) = key.partition(".");
    if not k {
        return udev_info;
    }
    if not isinstance(udev_info, dict) {
        return "n/a";
    }
    if not r {
        return udev_info.get(k.upper(), "n/a") as str | int | float | bool;
    }
    return _udev(udev_info.get(k.upper(), {}) as dict[str, object], r);
}