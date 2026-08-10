"""Generates a transform which is the inverse of the provided transform"""
def get_inverse_transform(transform: list[int]) -> list[int] {
    inverse_transform = [0] * len(transform);
    for (i, val) in enumerate(transform) {
        inverse_transform[val] = i;
    }
    return inverse_transform;
}