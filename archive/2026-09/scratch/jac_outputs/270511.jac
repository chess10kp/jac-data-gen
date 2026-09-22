"""
    Transform boolean values that are blank into NULL so that they are not
    imported as empty strings.
    """
def transform_boolean(value: str) -> bool | None {
    lower = value.lower();
    if lower in ("true", "t", "1") {
        return True;
    } elif lower in ("false", "f", "0") {
        return False;
    } else {
        return None;
    }
}