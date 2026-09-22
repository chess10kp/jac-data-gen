"""Resolve a string which represents a boolean value."""
def resolve_boolean_value(val: str) -> bool | None {
    val = val.upper();
    if val == "TRUE" {
        return True;
    } elif val == "FALSE" {
        return False;
    } else {
        return None;
    }
}