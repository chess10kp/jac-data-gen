"""test for y < x < z with tupples"""
def colorinterval(x: tuple[float, float], y: tuple[float, float], z: tuple[float, float]) -> bool {
    a = y[0] <= x[0] <= z[0];
    b = y[1] <= x[1] <= z[1];
    c = y[1] <= x[1] <= z[1];
    return a and b and c;
}