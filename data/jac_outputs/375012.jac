"""Convert file path into clickable form."""
def get_hyperlink(path: str) -> str {
    text = "Click to open in new tab";
    return f'<a href="{path}" target="_blank">{text}</a>';
}