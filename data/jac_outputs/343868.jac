"""
    Get at the fully qualified name of an object, e.g.
    an instance of a :class:`~py_trees.composites.Sequence`
    becomes 'py_trees.composites.Sequence'.
    """
def get_fully_qualified_name(instance: object) -> str {
    module = instance.__class__.__module__;
    builtin = str.__class__.__module__;
    if module is None or module == builtin {
        return instance.__class__.__name__;
    }
    return module + '.' + instance.__class__.__name__;
}