"""Convert the format_list into attrs that can be used with python bindings."""
def bindings_friendly_attrs(format_list: str | list[str] | None) -> list[str] {
    attrs = [];
    if format_list is not None {
        if isinstance(format_list, list) {
            attrs = format_list;
        } elif isinstance(format_list, str) {
            attrs = [format_list];
        }
    }
    return attrs;
}