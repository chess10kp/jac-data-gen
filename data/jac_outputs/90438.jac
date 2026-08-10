""" convert the given indexes back to text """
def convert_inds_to_text(inds: Any, ind2word: Any, preprocess: Any = False) -> object {
    words = [ind2word[word] for word in inds];
    return words;
}