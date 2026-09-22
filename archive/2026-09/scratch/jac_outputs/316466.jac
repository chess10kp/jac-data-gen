"""Check whether knowledge graph edges have weights.

Only valid if message has local knowledge graph."""
def kgraph_is_weighted(message: dict[str, dict[str, list[dict[str, str | int | float]]]]) -> bool {
    return all('weight' in `edge for `edge in message['knowledge_graph']['edges']);
}