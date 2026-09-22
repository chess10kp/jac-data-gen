"""dest wins"""
def dict_merge(source: Any, destination: Any) -> object {
    for (key, value) in source.items() {
        if isinstance(value, `dict) {
            `node = destination.setdefault(key, {});
            dict_merge(value, `node);
        } else {
            destination[key] = value;
        }
    }
    return destination;
}