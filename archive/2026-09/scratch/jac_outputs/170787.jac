"""Create string of node attributes, one key per line."""
def create_hover_text(
    node_attributes: dict[str, dict[str, bool | str | None]],
    only_use: set[str] = set()
) -> str {
    info = [];
    for (key, value) in node_attributes['attr'].items() {
        if not only_use or key in only_use {
            info.append(f'{key}: {value}');
        }
    }
    return '\n'.join(info);
}