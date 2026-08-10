"""
Formula:
Number of times term w appears in a document) / (Total number of terms in the document).
"""
def tf_score(word: str, sentence: str) -> float {
    word_frequency = 0;
    len_sentence = len(sentence);
    for token in sentence.split() {
        if word == token {
            word_frequency += 1;
        }
    }
    return word_frequency / len_sentence;
}