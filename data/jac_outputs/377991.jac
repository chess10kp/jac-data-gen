"""
    Return whether list_, or any nested sub-list of list_ contains value.
    >>> list_ = ["how", "now", "brown", 1]
    >>> nested_contains(list_, "now")
    True
    >>> nested_contains(list_, 1)
    True
    >>> nested_contains(list_, 3)
    False
    >>> list_ = ["how", ["now", "brown"], 1]
    >>> nested_contains(list_, "now")
    True
    >>> nested_contains([], 5)
    False
    >>> nested_contains([5], 5)
    True
    """
def nested_contains(list_: list, value: object) -> bool {
    if not isinstance(list_, list) {
        return (list_ == value);
    } else {
        return `any([nested_contains(item, value) for item in list_]);
    }
}