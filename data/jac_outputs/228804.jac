"""
    Rebuild the shortest path from source to target as a list and its cost

            Parameters:
                    source (int): the vertex choose as source
                    target (int): the vertex choose as target
                    prev (dict): a dictionary with vertex as key and last previous vertex in the path from the source as value
                                -1 if it is not reachable
                    dist (dict): a dictionary with vertex as key and the total distance from the source as value
            Returns:
                    path (list): the sequence of nodes covered
                    cost (int): cost of the path
    """
def getShortestPath(
    source: int,
    target: int,
    prev: dict[int, int],
    dist: dict[int, int]
) -> tuple[list[int], int] {
    path = [target];
    cost = dist[target];
    while target != source {
        path.append(prev[target]);
        target = prev[target];
    }
    path.reverse();
    return (path, cost);
}