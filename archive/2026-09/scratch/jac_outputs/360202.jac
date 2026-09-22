"""Returns the first non-null element of the iterable.

    If there is no non-null elements in the iterable--or the iterable is
    empty--the default value is returned.

    If the value to be returned is an exception object, it is raised instead.
    """
def icoalesce(iterable: Any, `default: Any = None) -> object {
    result = next(
        (
            i
            for i in iterable
            if (i is not None)
        ),
        `default
    );
    if isinstance(result, Exception) {
        raise result;
    }
    return result;
}