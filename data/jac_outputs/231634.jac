"""
    :return: a single value from lists, tuples or sets with one item;
    otherwise, the value itself if not empty or the default if it is.
    """
def reduce_value(value: Any, `default: Any = '') -> object {
    if hasattr(value, '__len__') {
        vlen = len(value);
        if (vlen == 0) {
            return `default;
        } elif (vlen == 1) {
            if isinstance(value, `set) {
                return value.pop();
            } elif isinstance(value, (`list, `tuple)) {
                return value[0];
            }
        }
    }
    return `default if (value is None) else value;
}