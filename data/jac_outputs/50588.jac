"""
    Return a list of Hypothesis objects, sorted by descending average log probability.
    """
def sort_hyps(
    hyps: Any, vocab_size: Any, key_token_ids: Any, complete_hyps: Any
) -> object {
    return sorted(
        hyps,
        key=lambda (h: Any) { h.score(vocab_size, key_token_ids, complete_hyps); },
        reverse=True
    );
}