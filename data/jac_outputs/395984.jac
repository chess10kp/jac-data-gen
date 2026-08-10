"""Return the last item of an iterable or 'default' if there's none."""
def last(iterable: Any, *`default: Any) -> object {
    try {
        iterable = reversed(iterable);
    } except TypeError {
        ;
    } else {
        return next(iterable, *`default);
    }
    iterable = iter(iterable);
    x = next(iterable, *`default);
    for x in iterable {
        ;
    }
    return x;
}