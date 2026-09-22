"""Creates indices from sequences."""
def create_index_from_sequences(sequences: list[list[int]]) -> list[int] {
    return [index for index in range(len(sequences))];
}