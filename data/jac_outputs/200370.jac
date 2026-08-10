"""Returns True if the exceptions have the same type and message."""
def exceptions_equal(exception1: Exception, exception2: Exception) -> bool {
    return `type(exception1) == `type(exception2) and str(exception1) == str(exception2);
}