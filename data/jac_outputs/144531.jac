"""
    Creates a blank world out of size * size dots
    """
def create_blank_world(
    size_x: int = 20, size_y: int = 20, character: str = ". "
) -> list[list[str]] {
    world = [];
    for line in range(size_y) {
        world.append([]);
        world[line] = size_x * [character];
    }
    return world;
}