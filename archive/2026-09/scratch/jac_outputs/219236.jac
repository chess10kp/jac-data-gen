"""Transform single word to word index."""
def word2wid(word: str, word2id_dict: dict[str, int], OOV: str = "<oov>") -> int {
    for each in (word, word.lower(), word.capitalize(), word.upper()) {
        if each in word2id_dict {
            return word2id_dict[each];
        }
    }
    return word2id_dict[OOV];
}