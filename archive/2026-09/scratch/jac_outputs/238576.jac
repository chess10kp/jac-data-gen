"""Collect basic comparisons:
        Paraphrases should be closer to their seed than any transformation which significantly
        changes the meaning of the seed or modality of the seed.
    """
def _get_comparisons_3[T](idx: int, paraphrases: list[T], other: list[T]) -> list[list[tuple[int, T]]] {
    return [[(idx, p), (idx, o)] for p in paraphrases for o in other];
}