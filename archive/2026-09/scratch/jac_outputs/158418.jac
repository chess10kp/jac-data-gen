"""Extract exception messages to a list."""
def _get_errors(exc: BaseException) -> list[str] {
    if hasattr(exc, 'message') {
        errors = getattr(exc, 'messages') as list[str];
    } else {
        errors = [str(exc)];
    }
    return errors;
}