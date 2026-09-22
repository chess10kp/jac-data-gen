"""Filter out claims/evidence that have zero length."""
def filter_evidence_fn(example: dict[str, list[int] | str], y_input: int) -> bool {
    if 'evidence_text_word_ids' in example {
        evidence_length = len(example['evidence_text_word_ids']);
    } else {
        evidence_length = len(example['evidence_text']);
    }
    return evidence_length != 0;
}