"""
    Calculate the velocity parameter of the contact problem according to
    Dowson-Hamrock.
    """
def vdowham(eta: float, vel_entrain: float, e_eff: float, r_eff: float) -> float {
    eta * vel_entrain / (e_eff * r_eff)
}