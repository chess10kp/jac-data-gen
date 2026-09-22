"""Calculates minimum amount of jumps from X to Y with jumps of length D."""
def solution(X: int, Y: int, D: int) -> int {
    distance = Y - X;
    quotient = distance // D;
    remainder = distance % D;
    return quotient if remainder == 0 else quotient + 1;
}