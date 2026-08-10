"""Convert list of words to list of corresponding id.

    Args:
        corpus: a list of str words.
        word2id: a dictionary that maps word to id.
    Returns:
        converted corpus, i.e., list of word ids.
    """
def convert_words_to_id(corpus: list[str], word2id: dict[str, int]) -> list[int] {
    new_corpus = [-1] * len(corpus);
    for (i, word) in enumerate(corpus) {
        if word in word2id {
            new_corpus[i] = word2id[word];
        }
    }
    return new_corpus;
}