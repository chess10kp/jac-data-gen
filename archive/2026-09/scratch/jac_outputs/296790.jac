""" pick color for charge states"""
def color_picker(total_items: int, current_item: int, palette: list[str]) -> str {
    if total_items < len(palette) {
        return palette[current_item];
    }
    return palette[current_item % len(palette)];
}