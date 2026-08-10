"""Strip charset from the content type string."""
def strip_charset(content_type: str) -> str {
    return content_type.split(';')[0];
}