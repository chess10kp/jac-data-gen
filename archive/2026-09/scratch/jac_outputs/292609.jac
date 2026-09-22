"""
product(iterable) is a product of all elements in iterable.  If
init is given, the multiplication starts with init instead of the
first element in iterable. If the iterable is empty, then init or
1 will be returned.

If iterable is an iterator, it will be exhausted.
"""
def product(iterable: list[int], `init: int | None = None) -> int {
    if (`init is None) {
        items = list(iterable);
        if len(items) == 0 {
            return 1;
        }
        result = items[0];
        for i = 1 while i < len(items) with i += 1 {
            result *= items[i];
        }
        return result;
    }
    result = `init;
    for item in iterable {
        result *= item;
    }
    return result;
}