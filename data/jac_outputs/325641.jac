"""Convert a fully-qualified module.function name to (module, function) - stolen from Django."""
def get_mod_func(callback: str) -> tuple[str, str] {
    try {
        dot = callback.rindex('.');
    } except ValueError {
        return (callback, '');
    }
    (callback[:dot], callback[dot + 1:])
}