"""Returns the word with the highest occurence given a word sequence."""
def next_word_max_solution(prev_seq: str, counts: dict[str, dict[str, int]], N: int) -> str {
    token_seq = " ".join(prev_seq.split()[-(N - 1):]);
    max_successor = max(counts[token_seq].items(), key=lambda (k: tuple[str, int]) { k[1] })[0];
    return max_successor;
}