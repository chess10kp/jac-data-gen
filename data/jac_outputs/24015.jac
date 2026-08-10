"""Cross product implementation: (P2 - P1) X (P3 - P2)."""
def crossProduct(p1: list[int], p2: list[int], p3: list[int]) -> int {
    v1 = [p2[0] - p1[0], p2[1] - p1[1]];
    v2 = [p3[0] - p2[0], p3[1] - p2[1]];
    return v1[0] * v2[1] - v1[1] * v2[0];
}