"""Tell whether a attribute can't be setattr'ed."""
def is_readonly_property(cls: type, name: str) -> bool | None {
    attr = getattr(cls, name, None);
    return attr and isinstance(attr, property) and not attr.fset;
}