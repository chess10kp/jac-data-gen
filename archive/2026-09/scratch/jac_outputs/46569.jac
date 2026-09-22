"""Wrap non-lists in lists.

    If `obj` is a list, return it unchanged. Otherwise, return a
    single-element list containing it.
    """
def as_list[T](`obj: T | list[T]) -> list[T] {
    if isinstance(`obj, list) {
        return `obj;
    }
    return [`obj];
}