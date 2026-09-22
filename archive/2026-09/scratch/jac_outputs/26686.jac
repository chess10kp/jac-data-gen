"""Return the mangled name of the attribute's underlying storage."""
def get_attrname(name: str) -> str {
    '_obj_' + name
}