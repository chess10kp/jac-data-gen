"""Get the fully-qualified name of an object (including module)."""
def _qualname(`obj: Callable[..., object]) -> str {
    return `obj.__module__ + '.' + `obj.__qualname__;
}