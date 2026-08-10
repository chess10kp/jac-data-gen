"""Return the first non-repeating character in the string."""
def non_repeating(given_string: str) -> str | None {
    char_count = {};
    for char in given_string {
        if char not in char_count {
            char_count[char] = 1;
        } else {
            char_count[char] += 1;
        }
    }
    for char in given_string {
        if char_count[char] == 1 {
            return char;
        }
    }
    return None;
}