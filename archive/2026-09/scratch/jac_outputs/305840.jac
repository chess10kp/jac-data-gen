"""Checks if a field name has one dot in it, e.g. BuildingCode.Value."""
def is_zero_depth_field(name: str) -> bool {
    if name.find('.') != -1 and name.find('.') == name.rfind('.') {
        return True;
    }
    return False;
}