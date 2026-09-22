"""Pads a batch of token sequences to a common length."""
def pad_batch(batch_tokens: list[list[str]]) -> tuple[list[list[str]], list[int]] {
    max_length = 0;
    for tokens in batch_tokens {
        max_length = max(max_length, len(tokens));
    }
    lengths = [];
    for tokens in batch_tokens {
        length = len(tokens);
        tokens += [""] * (max_length - length);
        lengths.append(length);
    }
    return (batch_tokens, lengths);
}