"""scalar multiply a list"""
def scalarmult(scalar: int, list1: list[int]) -> list[int] {
    return [scalar * elt for elt in list1];
}