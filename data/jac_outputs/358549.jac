"""escape special characters in a string for use in search"""
def string_escape(string: str) -> str {
    return string.replace("\\", "\\\\").replace("\"", "\\\"");
}