"""Tests if name is reserved

    Names beginning with 'xml' are reserved for future standardization"""
def is_reserved_name(name: str | None) -> bool {
    if name {
        return name[:3].lower() == 'xml';
    }
    return False;
}