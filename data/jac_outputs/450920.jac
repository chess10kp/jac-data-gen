"""
    Returns text with removed stop words
    Keyword arguments:
    text_all -- list of all texts (list of str)
    cached_stop_words -- list of all stopwords (list of str)
    """
def stop_word_removal(text_all: Any, cached_stop_words: Any) -> object {
    new_text_all = [];
    for text in text_all {
        text1 = ' '.join(
            [
                word
                for word in text.split()
                if (word not in cached_stop_words)
            ]
        );
        new_text_all.append(text1);
    }
    return new_text_all;
}