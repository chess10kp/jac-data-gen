"""Determine the type of a value, returning a full-path module.name string."""
def DetermineType[T](value: T) -> str | None {
    object_type = type(value);
    if not hasattr(object_type, '__name__') {
        return None;
    }
    type_string = getattr(object_type, '__module__', '');
    if type_string {
        type_string += '.';
    }
    type_string += object_type.__name__;
    return type_string;
}