"""Check if a string has a pair appearing twice without overlapping."""
def has_double_pair(text: str) -> bool {
    for i in range(len(text) - 3) {
        if text.count(f"{text[i]}{text[i + 1]}") >= 2 {
            return True;
        }
    }
    return False;
}