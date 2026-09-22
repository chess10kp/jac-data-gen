"""Given the location of the head of the snake, returns an action for that location."""
def get_action(head: tuple[int, int], M: int, N: int) -> int {
    if head == (0, 0) {
        return 2;
    }
    if head[0] == 0 {
        return 1;
    }
    if head[1] == N - 1 {
        return 0;
    }
    if head[1] % 2 == 0 {
        if head[0] == M - 1 {
            return 3;
        }
        return 2;
    }
    if head[0] == 1 {
        return 3;
    }
    return 0;
}