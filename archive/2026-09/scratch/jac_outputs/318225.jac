""" returns obj if it is not None, otherwise returns default """
def first_not_none[T](`obj: T | None, `default: T) -> T {
    return `default if `obj is None else `obj;
}