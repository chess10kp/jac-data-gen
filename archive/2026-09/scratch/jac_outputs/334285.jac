"""Replaces all keys with vals from replacement_dict in font_name."""
def replace_font_name(font_name: str, replacement_dict: dict[str, str]) -> str {
    for (key, val) in replacement_dict.items() {
        font_name = font_name.replace(key, val);
    }
    return font_name;
}