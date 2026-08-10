"""Check if two array shapes are compatible for broadcasting."""
def _broadcastable_shapes(shape_1: list[int], shape_2: list[int]) -> bool {
    return all(
        s1 == s2 or s1 == 1 or s2 == 1
        for (s1, s2) in zip(shape_1[::-1], shape_2[::-1])
    );
}