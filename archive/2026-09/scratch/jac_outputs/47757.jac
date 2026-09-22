"""
    For a given in-memory sequence of texts,
    return the first column of the embedded csv formatted as a string.
    """
def column_one(text: Any) -> object {
    list_of_words = [];
    lines = text.splitlines();
    for line in lines {
        fields = line.split("\t");
        item1 = fields[0];
        list_of_words.append(item1);
    }
    return " ".join(list_of_words);
}