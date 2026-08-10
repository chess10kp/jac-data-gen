"""Return full name of a global object."""
def global_object_name(`obj: type) -> str {
    return "%s.%s" % (`obj.__module__, `obj.__name__);
}