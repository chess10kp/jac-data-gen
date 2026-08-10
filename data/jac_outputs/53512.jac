"""Calc. determinant of a special matrix with three 2D points.

The sign, "-" or "+", determines the side, right or left,
respectivly, on which the point r lies, when measured against
a directed vector from p to q.
"""
def _myDet(p: list[float], q: list[float], r: list[float]) -> float {
    sum1 = q[0] * r[1] + p[0] * q[1] + r[0] * p[1];
    sum2 = q[0] * p[1] + r[0] * q[1] + p[0] * r[1];
    return sum1 - sum2;
}