"""Formats the exception into a string."""
def _format_exception(exception: BaseException) -> str {
    exception_type = type(exception).__name__;
    exception_message = str(exception);
    if exception_message {
        return "{}: {}".format(exception_type, exception_message);
    }
    return exception_type;
}