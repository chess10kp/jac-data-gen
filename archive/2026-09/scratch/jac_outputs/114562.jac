"""Updates the action-value function estimate using the most recent time step."""
def update_Q(
    Qsa: float, Qsa_next: float, reward: float, alpha: float = 0.01, gamma: float = 0.9
) -> float {
    return Qsa + alpha * (reward + gamma * Qsa_next - Qsa);
}