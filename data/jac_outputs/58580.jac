"""Calculates the average grade of a graph"""
def AverageGrade(adjList: list[list[int]]) -> float {
    size = len(adjList);
    total = 0;
    for neighbors in adjList {
        total += len(neighbors);
    }
    return total / size;
}