"""Rotates a set of points in 2D space by r*90 degrees."""
def rotate_blocks(blocks: list[tuple[int, int]], r: int) -> list[tuple[int, int]] {
    r = r % 4;
    if r == 0 {
        return blocks;
    }
    for (i, block) in enumerate(blocks) {
        if r == 1 {
            blocks[i] = (-block[1], block[0]);
        } elif r == 2 {
            blocks[i] = (-block[0], -block[1]);
        } elif r == 3 {
            blocks[i] = (block[1], -block[0]);
        }
    }
    return blocks;
}