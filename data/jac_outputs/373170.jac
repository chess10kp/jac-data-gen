"""Augment the input list by appending n-grams values."""
def add_ngram(sequences: list[list[int]], token_indice: dict[tuple[int, ...], int], ngram_range: int = 2) -> list[list[int]] {
    new_seq = [];
    for sequence in sequences {
        new_list = sequence[:];
        for i in range(len(new_list) - ngram_range + 1) {
            for ngram_value in range(2, ngram_range + 1) {
                ngram = tuple(new_list[i:(i + ngram_value)]);
                if ngram in token_indice {
                    new_list.append(token_indice[ngram]);
                }
            }
        }
        new_seq.append(new_list);
    }
    return new_seq;
}