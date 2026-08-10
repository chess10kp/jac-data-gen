"""Get infinitive form of a conjugated Spanish verb, or None if not found."""
def infinitve(conjugate: str, infinitive_map: dict[tuple[str, ...], str]) -> str | None {
    conjugate = conjugate.lower();
    for word_list in infinitive_map {
        if conjugate in word_list {
            infinitive = infinitive_map[word_list];
            return infinitive if infinitive else None;
        }
    }
    return None;
}