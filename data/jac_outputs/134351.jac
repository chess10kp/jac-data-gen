"""Format and return a header line."""
def packHeader(name: str | bytes, *values: str | int | bytes) -> bytes {
    if isinstance(name, str) {
        name = name.encode('ascii');
    }
    name = name.title();
    values = list(values);
    for (i, value) in enumerate(values) {
        if isinstance(value, str) {
            values[i] = value.encode('iso-8859-1');
        } elif isinstance(value, int) {
            values[i] = str(value).encode('ascii');
        }
    }
    value = b', '.join(values);
    return name + b': ' + value;
}