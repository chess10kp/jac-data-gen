""" add vectors """
def vadd(vector1: tuple[int | float, int | float], vector2: tuple[int | float, int | float]) -> tuple[int | float, int | float] {
    return (vector1[0] + vector2[0], vector1[1] + vector2[1]);
}