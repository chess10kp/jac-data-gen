"""Escape markdown special symbols."""
def md_table_escape(string: str) -> str {
    to_escape = [
        "\\", "`", "*", "_",
        "{", "}", "[", "]", "(", ")",
        "#", "|", "+", "-", ".", "!"
    ];
    for item in to_escape {
        string = string.replace(item, f"\\{item}");
    }
    return string.replace("\n", " ");
}