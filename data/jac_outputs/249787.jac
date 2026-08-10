"""Contruct a vector going from p1 to p2.

    p1, p2 - python list wth coordinates [x,y,z].

    Return a list [x,y,z] for the coordinates of vector
    """
def create_vector(p1: list[int], p2: list[int]) -> list[int] {
    [x - y for (x, y) in zip(p2, p1)]
}