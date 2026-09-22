"""Determines whether the tile at (`index_i`, `index_j`) is occupied."""
def is_occupied(index_i: int, index_j: int, tile_arrangement: list[list[str]]) -> bool {
    if not 0 <= index_i <= len(tile_arrangement) - 1 {
        raise IndexError;
    }
    if not 0 <= index_j <= len(tile_arrangement[0]) - 1 {
        raise IndexError;
    }
    return tile_arrangement[index_i][index_j] == "#";
}