"""Import a class from a string and return a reference to it.

THIS IS A GIANT SECURITY VULNERABILITY.
"""
def import_class(name: str | int | float | bool) -> str | int | float | bool | type {
    if not isinstance(name, str) {
        return name;
    }
    package = ".".join(name.split(".")[:-1]);
    class_name = name.split(".")[-1];
    mod = __import__(package, fromlist=[class_name]);
    return getattr(mod, class_name);
}