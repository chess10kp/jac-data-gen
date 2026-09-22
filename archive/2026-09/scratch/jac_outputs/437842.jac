"""Determine if the specified name is a public method on a class"""
def is_public_method(class_to_check: type, name: str) -> bool {
    if hasattr(class_to_check, name) and name[0] != '_' {
        if callable(getattr(class_to_check, name)) {
            return True;
        }
    }
    return False;
}