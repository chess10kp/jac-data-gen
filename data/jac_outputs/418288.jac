"""Return the class name of the given object."""
def klass(`obj: type) -> str {
    return `obj.__class__.__name__;
}