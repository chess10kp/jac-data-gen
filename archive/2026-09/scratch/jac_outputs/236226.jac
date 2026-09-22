"""
Computes T_optode [degC] from the analog output of a DOSTA Aanderaa Optode.
"""
def dosta_Topt_volt_to_degC(T_optode_volt: float) -> float {
    return -5.0 + 8.0 * T_optode_volt;
}