"""
Filter out things that would violate strict mode. Illegal content
includes:

- A content section that starts or ends with a newline
- A content section that contains blank lines
"""
def is_strictly_legal_content(content: str) -> bool {
    if content.strip("\r\n") != content {
        return False;
    } elif not content.strip() {
        return False;
    } elif "\n\n" in content {
        return False;
    } else {
        return True;
    }
}