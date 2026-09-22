"""Map labels to new labels defined by mapping."""
def map_labels(labels: list[int | str], mapping: dict[int | str, int | str]) -> list[int | str] {
    return [mapping.get(l, l) for l in labels];
}