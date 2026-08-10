"""Gets index of text in string."""
def index_in_str(text: str, substring: str, starting: int = 0) -> int {
    search_in = text[starting:];
    if substring in search_in {
        return search_in.index(substring);
    }
    return -1;
}