"""Filter out claims/evidence that have zero length."""
def filter_claim_fn(example: dict[str, list[int] | str], _: int) -> bool {
    if 'claim_text_word_ids' in example {
        claim_length = len(example['claim_text_word_ids']);
    } else {
        claim_length = len(example['claim_text']);
    }
    return claim_length != 0;
}