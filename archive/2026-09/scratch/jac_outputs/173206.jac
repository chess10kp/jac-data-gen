"""Returns parent layer indices for a given layer index."""
def get_layer_parents(adjList: list[list[int]], lidx: int) -> list[int] {
    [e[0] for e in adjList if e[1] == lidx]
}