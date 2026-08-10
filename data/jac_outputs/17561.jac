"""
Selects n random nodes from a list of nodes and returns the list.
"""
def selectNRandom(nodes: list[str], N: int) -> list[str] {
    import random;
    random.shuffle(nodes);
    return nodes[:N];
}