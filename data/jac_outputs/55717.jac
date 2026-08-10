"""Check if position is on board."""
def on_board(position: tuple[int, int]) -> bool {
    return 0 <= position[0] < 8 and 0 <= position[1] < 8;
}