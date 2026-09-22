"""Format a function annotation as a string."""
def formatannotation(
    annotation: type | str | int | float | bool | list | tuple | dict | None,
    base_module: str | None = None
) -> str {
    if getattr(annotation, '__module__', None) == 'typing' {
        return repr(annotation).replace('typing.', '');
    }
    if isinstance(annotation, type) {
        if annotation.__module__ in ('builtins', base_module) {
            return annotation.__qualname__;
        }
        return annotation.__module__ + '.' + annotation.__qualname__;
    }
    return repr(annotation);
}