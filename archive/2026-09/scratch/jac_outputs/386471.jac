"""assume the length of encode1 and encode2 are n, time complexity is
    O(n), space complexity is O(n)
    """
def _vector_similarity(encode1: list[float], encode2: list[float]) -> float {
    return sum([x * y for (x, y) in zip(encode1, encode2)]);
}