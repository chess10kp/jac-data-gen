""" Converts an HTML color string like FF7F00 or #c0ffee to RGB. """
def from_html(html_color: Any) -> object {
    num = int(html_color.lstrip('#'), 16);
    return [(num // 65536), ((num // 256) % 256), (num % 256)];
}