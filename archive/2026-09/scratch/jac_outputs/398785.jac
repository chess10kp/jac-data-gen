"""Format configuration output for a settings section."""
def format_configuration(
    name: str, value: str, nearest: str, path: str, item_type: str
) -> dict[str, str] {
    name = name.replace('_', ' ');
    if name == "paging" {
        item_type = "radio";
    } elif name == "type" {
        item_type = "blank";
    }
    return {
        'name': name,
        'value': value,
        'nearest': nearest,
        'path': path,
        'type': item_type
    };
}