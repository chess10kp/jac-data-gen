"""Format a position dict as 'line.character' (1-based)."""
def format_pos(pos: dict[str, int]) -> str {
    return '{}.{}'.format(pos['line'] + 1, pos['character'] + 1);
}