"""word pair distance counts the number
    of words which lie between those of a given pair.
    """
def wordPairDist(word1: Any, word2: Any, words: Any) -> object {
    if ((word1 in words) and (word2 in words)) {
        return abs((words.index(word1) - words.index(word2)));
    }
    return -1;
}