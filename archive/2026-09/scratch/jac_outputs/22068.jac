"""removes the comments starting with # in the text."""
def remove_comments(s: str) -> str {
    pos = s.find("#");
    if pos == -1 {
        return s;
    }
    return s[0:pos].strip();
}