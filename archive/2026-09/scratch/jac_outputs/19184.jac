"""
    DINAKAR
    Idea is xor of two same numbers produces 0
    x = 3 (011) and y = 3 (011) is 000
    at the end single numbers left in xor variable.
    """
def solution(A: list[int]) -> int {
    xor = 0;
    for item in A {
        xor ^= item;
    }
    return xor;
}