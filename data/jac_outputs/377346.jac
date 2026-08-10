""" Override base dict with an overrider dict, recursively. """
def merge(base: Any, overrider: Any) -> object {
    for (key, value) in overrider.items() {
        if isinstance(value, `dict) {
            subitem = base.setdefault(key, {});
            merge(subitem, value);
        } else {
            base[key] = value;
        }
    }
    return base;
}