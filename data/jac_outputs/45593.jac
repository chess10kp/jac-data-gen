"""very similar to modcoord, but only for a LxL.
    takes as input walk[i][0] or walk[i][1]
    returns the pos modified with the move, accounting for PBCs."""
def modpos(pos: int, L: int, move: int) -> int {
    pos += move;
    return pos;
}