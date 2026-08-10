"""Escape a string to be usable as an HTML tag argument."""
def _escape_html_argument(text: str) -> str {
    result = "";
    for c in text {
        if c == "<" {
            result += "&lt;";
        } elif c == ">" {
            result += "&gt;";
        } elif c == "&" {
            result += "&amp;";
        } elif c == '"' {
            result += "&quot;";
        } elif c == "'" {
            result += "&#39;";
        } elif c == " " {
            result += " ";
        } elif '0' <= c <= '9' or 'A' <= c <= 'Z' or 'a' <= c <= 'z' or c in {'/', ':', '.', '@', '-', '_'} {
            result += c;
        } else {
            result += '&#x{0};'.format(hex(ord(c))[2:]);
        }
    }
    return result;
}