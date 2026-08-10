"""Convert a string argument to a subclass of basestring."""
def _to_basestring(value: str | bytes) -> str {
    if isinstance(value, str) {
        return value;
    }
    if not isinstance(value, bytes) {
        raise TypeError("Expected bytes, unicode, or None; got %r" % type(value));
    }
    return value.decode("utf-8");
}