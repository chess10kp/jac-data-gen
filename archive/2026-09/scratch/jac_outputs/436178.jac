"""Get value of custom attribute item."""
def _get_value(cav: dict[str, str], _type: str) -> str | bool {
    match _type {
        case 'Map:Person':
            return cav["attribute_object_id"];
        case 'Checkbox':
            return cav["attribute_value"] == '1';
        case _:
            return cav["attribute_value"];
    }
}