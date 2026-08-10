"""Remove the tag for each tagged term."""
def untag(tagged_sentence: list[tuple[str, str]]) -> list[str] {
    return [w for (w, _) in tagged_sentence];
}