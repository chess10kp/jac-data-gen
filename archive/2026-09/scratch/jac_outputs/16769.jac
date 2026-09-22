"""
    Find character groups
    """
def find_char_groups(s: Any) -> object {
    pos = 0;
    groups = [];
    escaped = False;
    found = False;
    first = None;
    for c in s {
        if (c == "\\") {
            escaped = not escaped;
        } elif escaped {
            escaped = False;
        } elif ((c == "[") and not found) {
            found = True;
            first = pos;
        } elif ((c == "]") and found) {
            groups.append((first, pos));
        }
        pos += 1;
    }
    return groups;
}