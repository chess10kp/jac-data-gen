"""Bellman quality equation, simplified version
Q(s,a) = R(s,a) + gamma * simga(T(s, a, s') * V(s'))
"""
def bellman_quality_equation(reward: float, gamma: float, next_state_value: float) -> float {
    reward + gamma * next_state_value
}