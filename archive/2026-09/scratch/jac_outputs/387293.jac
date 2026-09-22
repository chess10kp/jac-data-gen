"""Returns a reward given the movement of the snake [-1 -> 1]."""
def dist_reward(old: float, act: float) -> float {
    d = act - old;
    if -10 <= d <= 10 {
        return -d / 10;
    }
    return 0;
}