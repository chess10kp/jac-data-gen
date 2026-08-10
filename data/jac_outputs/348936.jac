"""Escape special HTML characters (& <>)."""
def escape_html_chars(str_val: str | None) -> str | None {
    if str_val is None {
        return None;
    }
    output = str_val;
    output = output.replace('&', '&amp;');
    output = output.replace(' ', '&nbsp;');
    output = output.replace('>', '&gt;');
    output = output.replace('<', '&lt;');
    return output;
}