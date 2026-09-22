"""
Given one dimension move (x or y), return the shorter move comparing with opposite move.
The Board is actually round, ship can move to destination by any direction.
Example: Given board size = 5, move = 3, opposite_move = -2, return -2 since abs(-2) < abs(3).
"""
def get_shorter_move(move: int, size: int) -> int {
    if move == 0 {
        return 0;
    } elif move > 0 {
        opposite_move = move - size;
    } else {
        opposite_move = move + size;
    }
    return min([move, opposite_move], key=abs);
}