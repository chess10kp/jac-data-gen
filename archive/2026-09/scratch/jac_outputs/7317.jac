"""Returns missing elements to a reflexive relation."""
def reflexive_missing_elements(
    relation: list[list[object]], set: list[object]
) -> list[tuple[object, object]] {
    return [(element, element) for element in set if [element, element] not in relation];
}