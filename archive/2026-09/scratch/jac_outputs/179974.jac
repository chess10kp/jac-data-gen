""" Get a list of non-private class methods. """
def get_class_methods(cls: type) -> list[callable] {
    return [
        getattr(cls, func)
        for func in dir(cls)
        if not func.startswith('__') and callable(getattr(cls, func))
    ];
}