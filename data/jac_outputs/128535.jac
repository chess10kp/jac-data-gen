"""
Remove keys from dict; dot notation for nested keys.
Silently ignores keys that do not exist.
"""
def filter_dict(d: dict[str, object], keys: str | list[str]) -> dict[str, object] {
    if isinstance(keys, str) {
        keys = [keys];
    }
    for key in keys {
        if "." in key {
            innerkey = ".".join(key.split(".")[1:]);
            rkey = key.split(".")[0];
            if rkey in d {
                d[rkey] = filter_dict(d[rkey] as dict[str, object], innerkey);
            } else {
                continue;
            }
        } else {
            d.pop(key, None);
        }
    }
    return d;
}