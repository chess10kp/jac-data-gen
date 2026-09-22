"""Generate response dict with intent and extracted entity tags."""
def response_generator(intent: str, tags: list[str], tokens: list[str]) -> dict[str, str | dict[str, list[str]]] {
    entities: dict[str, list[str]] = {};
    for (idx, tag_item) in enumerate(tags) {
        if tag_item != 'o' {
            tag = tag_item[2:];
            if not tag in entities {
                entities[tag] = [tokens[idx]];
            } else {
                entities[tag].append(tokens[idx]);
            }
        }
    }
    return {'Intent': intent, 'Entities': entities};
}