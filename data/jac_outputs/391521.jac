"""Return marker in grid at given location."""
def getGridMarker(location: list[int], grid: list[list[str]]) -> str {
    return grid[location[0]][location[1]];
}