"""
Calculate the average range rate. eqn 6.37 in Montenbruck 2000.
tc =  length of integration interval, i.e. length of CPI
Created: 04/04/17
"""
def fnCalculate_Bistatic_RangeRate(
    speed_light: float, tau_u1: float, tau_d1: float, tau_u2: float, tau_d2: float, tc: float
) -> float {
    (speed_light / tc) * ((tau_u2 + tau_d2) - tau_u1 - tau_d1)
}