"""Return grid edge size."""
def get_grid_size(grid: str) -> int {
    if not grid {
        return 0;
    }
    pos = grid.find('\n');
    if pos < 0 {
        return 1;
    }
    return pos;
}