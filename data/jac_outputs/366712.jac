"""Struct initializer

    >>> from emlearn import cgen
    >>> cgen.struct_init([ 1, 2, 3 ])
    "{ 1, 2, 3 }"
    """
def struct_init(*args: Any) -> object {
    return ('{ ' + ', '.join(str(a) for a in args) + ' }');
}