"""Returns True if a type is iterable, or False otherwise.

    Types passed to ``exclude`` will be considered not iterable.
    """
def isiterable(`obj: list | tuple | str | dict | set | bytes | range, exclude: tuple[type, ...] | list[type] | None = None) -> bool {
    excluded = exclude if exclude is not None else ();
    if any(isinstance(`obj, cls) for cls in excluded) {
        return False;
    }
    try {
        iter(`obj);
        return True;
    } except TypeError {
        return False;
    }
}