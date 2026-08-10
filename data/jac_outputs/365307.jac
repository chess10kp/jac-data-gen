"""Get nested field from list of objects or single instance."""
def get_nested_field(value: object | list[object], field: str) -> object {
    if field == '__self__' {
        return value;
    }
    fields = field.split('__');
    for fld in fields {
        if isinstance(value, list) {
            value = [getattr(v, fld) for v in value];
        } else {
            value = getattr(value, fld);
        }
    }
    return value;
}