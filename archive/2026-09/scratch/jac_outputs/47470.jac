"""Returns True if an object can be iterated over by using iter(obj)."""
def is_iterable(f: object) -> bool {
    try {
        iter(f as list[object]);
        return True;
    } except TypeError {
        return False;
    }
}