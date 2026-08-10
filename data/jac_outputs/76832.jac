"""Import and return a function by module path string, or return it if already callable."""
def import_function(function: str | callable) -> callable {
    if isinstance(function, str) {
        (m, f) = function.rsplit('.', 1);
        return getattr(__import__(m, {}, {}, ['']), f);
    }
    return function;
}