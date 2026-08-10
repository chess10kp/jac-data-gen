"""Given a list of texts, prints the number of characters of each paragraph.
        Keyword arguments:
            text_list -- a list of texts
            n -- return paragraphs of size > n characters
    """
def para_size_greater_than_n(para_list: Any, n: Any = 0) -> object {
    if (n > 0) {
        return [
            para
            for para in para_list
            if (len(para) > n)
        ];
    }
}