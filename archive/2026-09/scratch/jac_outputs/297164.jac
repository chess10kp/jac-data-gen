"""This function simply calculates the epsilon effective
    if you don't give the value for epsiln one or two it will consider it
    to be 0.9 by default"""
def epsilonEffective(epsilon1: float = 0.9, epsilon2: float = 0.9) -> float {
    1 / ((1 / epsilon1) + (1 / epsilon2) - 1)
}