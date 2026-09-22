"""
Approximates supersonic shock stand-off distance for the stagnation
point of an obstacle with equivalent radius R_n

Input variables:
    R_n     :   Obstacle radius
    rho_inf :   Freestream density
    rho_s   :   Density at point immediately behind shock
"""
def shock_standoff(R_n: float, rho_inf: float, rho_s: float) -> float {
    return R_n * (rho_inf / rho_s);
}