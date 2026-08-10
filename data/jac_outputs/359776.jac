"""Creating a corpus of all the tokens used."""
def create_vocab(data: list[str]) -> tuple[list[str], list[list[str]]] {
    tokenized_corpus = [sentence.split(' ') for sentence in data];
    vocabulary = [];
    for sentence in tokenized_corpus {
        for token in sentence {
            if token not in vocabulary {
                vocabulary.append(token);
            }
        }
    }
    return (vocabulary, tokenized_corpus);
}