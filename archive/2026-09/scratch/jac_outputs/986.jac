"""Helper function to make author link."""
def _format_author(url: str, full_name: str) -> str {
    return "<a class='more-info' href='%s'>%s</a>" % (url, full_name);
}