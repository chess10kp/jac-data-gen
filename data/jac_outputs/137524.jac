"""Counts no of whitespace in string and returns an int."""
def count_str_whitespace(mystr: Any) -> object {
    count = 0;
    for mychar in mystr {
        if mychar.isspace() {
            count += 1;
        }
    }
    return count;
}