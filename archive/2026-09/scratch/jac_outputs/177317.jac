"""Helper function returns total reward for snake_game."""
def state2int(points_earned: float, distance_reward: float) -> float | int {
    if points_earned == 0 {
        return distance_reward;
    } elif points_earned < 0 {
        return -2;
    } elif points_earned > 0 {
        return 2;
    }
    return 0;
}