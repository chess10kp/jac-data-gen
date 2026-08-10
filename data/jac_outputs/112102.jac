"""Move from old_position by move."""
def move_position(old_position: list[int], move: list[int]) -> tuple[int, ...] {
    return tuple(
        position + change for (position, change) in zip(old_position, move)
    );
}