"""Get the class full path name."""
def get_class_name(cls: type) -> str {
    return "{}.{}".format(cls.__module__, cls.__name__);
}