"""Map each token in the dataset to a unique integer id."""
def create_vocabulary(dataset: list[list[str]], terminal_token: str | None = '<e>') -> tuple[dict[str, int], list[str]] {
    vocabulary = {};
    reverse_vocabulary = [];
    if terminal_token is not None {
        vocabulary[terminal_token] = 0;
        reverse_vocabulary.append(terminal_token);
    }
    for sample in dataset {
        for token in sample {
            if token not in vocabulary {
                vocabulary[token] = len(vocabulary);
                reverse_vocabulary.append(token);
            }
        }
    }
    return (vocabulary, reverse_vocabulary);
}