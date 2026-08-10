"""Generate a goal board with an given size

    Args:
        s (int, s>=3): The size of goal board to generate, i.e. the width of the board.

    Returns:
        goal (list): A 2D list representing tiles of the goal board,
                    e.g., if the size given is 3, the goal is [[1,2,3],[4,5,6],[7,8,9]].
    """
def make_goal(s: int) -> list[list[int]] {
    arr = [i for i in range(1, s * s)];
    arr.append(0);
    return [[arr[i * s + j] for j in range(s)] for i in range(s)];
}