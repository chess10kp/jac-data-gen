enum Direction {
    NORTH = "NORTH",
    SOUTH = "SOUTH",
    EAST = "EAST",
    WEST = "WEST"
}

def opposite(d: Direction) -> Direction {
    pairs: dict = {
        Direction.NORTH: Direction.SOUTH,
        Direction.SOUTH: Direction.NORTH,
        Direction.EAST: Direction.WEST,
        Direction.WEST: Direction.EAST
    };
    return pairs[d];
}

with entry {
    print(opposite(Direction.NORTH).value);
}
