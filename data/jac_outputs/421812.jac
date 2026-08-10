"""Where nextQ is determined by the epsilon greedy choice that has already been made."""
def update_q(reward: float, gamma: float, alpha: float, oldQ: float, nextQ: float) -> float {
    return oldQ + alpha * (reward + gamma * nextQ - oldQ);
}