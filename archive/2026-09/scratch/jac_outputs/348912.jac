"""A more robust version."""
def is_subclass(cls: type, subclass: type) -> bool {
    try {
        return issubclass(cls, subclass);
    } except TypeError {
        return False;
    }
}