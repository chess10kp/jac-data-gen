"""
Objects that wraps function should provide a "__numba__" magic attribute
that contains a name of an attribute that contains the actual python
function object.
"""
def get_function_object(`obj: object) -> object {
    attr = getattr(`obj, "__numba__", None);
    if attr {
        return getattr(`obj, attr);
    }
    return `obj;
}