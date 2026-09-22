"""Find all occurrences of a pattern in a text of bases."""
def pattern_count(text: str, pattern: str) -> int {
    count = 0;
    pattern_length = len(pattern);
    text_length = len(text);
    for i in range(text_length - pattern_length + 1) {
        if text[i:i + pattern_length] == pattern {
            count += 1;
        }
    }
    return count;
}