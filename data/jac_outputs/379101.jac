"""
    Used in lines_intersection
    from:
    https://stackoverflow.com/questions/20677795/how-do-i-compute-the-intersection-point-of-two-lines-in-python
    """
def line_parameters_xy(pt_1: tuple[float, float], pt_2: tuple[float, float]) -> tuple[float, float, float] {
    a = pt_1[1] - pt_2[1];
    b = pt_2[0] - pt_1[0];
    c = pt_1[0] * pt_2[1] - pt_2[0] * pt_1[1];
    return (a, b, -c);
}