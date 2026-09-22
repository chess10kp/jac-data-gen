""" Return the number of words in the given text. """
def wordcount(text: Any) -> object {
    if (`type(text) == str) {
        return len(text.split(" "));
    } elif (`type(text) == `list) {
        return len(text);
    } else {
        raise ValueError(
            "Text to count words for must be of type str or of type list."
        );
    }
}