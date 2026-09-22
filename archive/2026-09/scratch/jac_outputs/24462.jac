"""Gets the name of underlying objects."""
def _get_name(f: Callable[..., object]) -> str {
    if hasattr(f, '__name__') {
        return getattr(f, '__name__') as str;
    }
    if hasattr(f, 'func') and hasattr(getattr(f, 'func', None), '__name__') {
        return getattr(getattr(f, 'func'), '__name__') as str;
    }
    return repr(f);
}