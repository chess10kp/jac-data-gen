"""Sets bookmarks as value for 'children' key entry of a root bookmark."""
def set_bookmark_children(json_root_object: dict[str, list[dict[str, str]]], bookmarks: list[dict[str, str]]) -> dict[str, list[dict[str, str]]] {
    json_root_object["children"] = bookmarks;
    return json_root_object;
}