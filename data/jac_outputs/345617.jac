"""Return the errno of an exception, or the first argument if errno is not available."""
def get_errno(e: Exception) -> int {
    try {
        return getattr(e, "errno");
    } except AttributeError {
        return e.args[0];
    }
}