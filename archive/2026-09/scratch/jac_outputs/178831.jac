"""Splits returned OSM elements into list of ways and list of nodes."""
def splitElements(osmElements: list[dict[str, str | int | list[int]]]) -> tuple[list[dict[str, str | int | list[int]]], list[dict[str, str | int | list[int]]]] {
    nodes = [];
    ways = [];
    garbage = [];
    for element in osmElements {
        if element['type'] == 'node' {
            nodes.append(element);
        } elif element['type'] == 'way' {
            ways.append(element);
        } else {
            garbage.append(element);
        }
    }
    return (ways, nodes);
}