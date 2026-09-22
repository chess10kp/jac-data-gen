""" stop_func"""
def stop_func(x: int | float, y: int | float) -> tuple[int | float, int | float] {
    c = x * y;
    c_s = x + y;
    return (c_s, c);
}