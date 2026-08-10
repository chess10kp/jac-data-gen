"""Check possibility of the movement."""
def check_move(x: int, y: int, possible_moves: list[tuple[int, int]]) -> bool {
    return (x - 1, y - 1) in possible_moves;
}