import from math { cos, sin, pi }

"""Convert lagtitude and longitude to xyz coordinate."""
def laglongToCoord(theta: float, phi: float) -> tuple[float, float, float] {
    theta = theta / 180 * pi;
    phi = phi / 180 * pi;
    return (sin(theta) * cos(phi), sin(phi), cos(theta) * cos(phi));
}