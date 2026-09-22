"""Gather statistics about the text, primarily the average word length."""
def average_word_length(txt: str) -> float {
    nw = len(txt.split());
    nc = len(txt);
    return nc / (nw + 1);
}