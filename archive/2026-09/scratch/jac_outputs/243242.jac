"""Build the index (P x D) -> N for all interactors of the current protein."""
def build_index(interactors: list[tuple[str, str]]) -> dict[tuple[str, str], int] {
    index = dict();
    sorted_interactors = sorted(list(interactors));
    for (p, d) in sorted_interactors {
        index[(p, d)] = sorted_interactors.index((p, d));
    }
    return index;
}