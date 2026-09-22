""" Retorna o menor valor entre dois valores """
def diff(value_a: int | float, value_b: int | float, position_a: int, position_b: int) -> tuple[int, float] {
    if not value_a or not value_b {
        return (101, 0);
    }
    if value_a < value_b {
        return (position_a, round(value_b - value_a, 2));
    } elif value_a > value_b {
        return (position_b, round(value_a - value_b, 2));
    } else {
        return (100, 0);
    }
}