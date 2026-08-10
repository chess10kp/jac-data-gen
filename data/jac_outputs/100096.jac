"""Sort mapping by complexity."""
def sortMapping(streamPair: list[dict[str, list[list[str]]] | str | int]) -> list[tuple[str, list[list[str]]]] {
    modified_mapping = streamPair[5] as dict[str, list[list[str]]];
    possible_mapping = [];
    for key in modified_mapping {
        modified_mapping[key] = list(modified_mapping[key]);
        modified_mapping[key].sort(key=lambda (item: list[str]) { len(item); }, reverse=True);
        possible_mapping.append((key, modified_mapping[key]));
    }
    possible_mapping.sort(key=lambda (item: tuple[str, list[list[str]]]) { len(item[0]); }, reverse=True);
    return possible_mapping;
}