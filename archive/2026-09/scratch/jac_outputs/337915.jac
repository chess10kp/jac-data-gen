"""Find the wrapper for the array with the highest priority.

    In case of ties, leftmost wins. If no wrapper is found, return None
    """
def get_array_prepare(*args: Any) -> object {
    wrappers = sorted(
        (getattr(x, '__array_priority__', 0), -i, x.__array_prepare__)
        for (i, x) in enumerate(args)
        if hasattr(x, '__array_prepare__')
    );
    if wrappers {
        return wrappers[-1][-1];
    }
    return None;
}