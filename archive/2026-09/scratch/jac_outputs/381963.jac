"""check for empty field value, post str.strip"""
def field_is_empty(field: Any) -> object {
    if (field and (str(field) != '') and (str(field).strip() != '')) {
        empty = False;
    } else {
        empty = True;
    }
    return empty;
}