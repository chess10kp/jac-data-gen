"""Convert a variable to a list."""
def asList(x: object) -> list[object] {
    if isinstance(x, list) {
        return x;
    } elif isinstance(x, tuple) {
        return list(x);
    } elif not hasattr(x, '__iter__') {
        return [x];
    } else {
        raise ValueError('Could not convert {} to a list'.format(str(x)));
    }
}