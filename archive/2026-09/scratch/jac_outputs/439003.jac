"""
    Returns a string defining a set of minecraft fill coordinates relative to the actor.
    In minecraft, the y axis denotes the vertical (non-intuitively).
    """
def fill_point(x: int | float | str, y: int | float | str, z: int | float | str, _: int) -> str {
    return f'~{int(x)} ~{int(z)} ~{int(y)}';
}