"""Get the name of a function."""
def funcname(func: Callable[..., None]) -> str {
    while hasattr(func, "func") {
        func = getattr(func, "func") as Callable[..., None];
    }
    try {
        return func.__name__;
    } except Exception {
        return str(func);
    }
}