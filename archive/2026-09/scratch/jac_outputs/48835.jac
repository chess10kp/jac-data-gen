"""Return the name of a type, e.g.:
typeName(int) => 'int'
typeName(Foo) => 'Foo'
typeName((int,str)) => 'int or str'
"""
def typeName(ty: type | tuple[type, ...]) -> str {
    if isinstance(ty, tuple) {
        return " or ".join(t.__name__ for t in ty);
    }
    return ty.__name__;
}