glob SCALE_HEIGHT_M = 44330.0;
glob EXPONENT = 5.255;

"""Calculates the pressure at sealevel when given a known altitude in meters. Returns a value in Pascals."""
def read_sealevel_pressure(pressure: float, altitude_m: float = 0.0) -> float {
    pressure / pow(1.0 - altitude_m / SCALE_HEIGHT_M, EXPONENT)
}