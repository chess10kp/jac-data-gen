"""Concatenate paragraphs constituting the question body."""
def concat_body_paragraphs(body_candidates: list[str]) -> str {
    return ' '.join(' '.join(body_candidates).split());
}