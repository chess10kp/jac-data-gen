"""Count number of character (char) in the beginning of string (data) """
def count_leading(data: str, char: str) -> int {
    for (i, c) in enumerate(data) {
        if c != char {
            return i;
        }
    }
    return len(data);
}