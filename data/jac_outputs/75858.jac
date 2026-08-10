"""Addition of two lists element-wise."""
def list_math_addition(a: list[int], b: list[int]) -> list[int] {
    return [a[i] + b[i] for i in range(len(a))];
}